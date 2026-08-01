import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Export/import manual de backup, 100% local — nu există sincronizare
/// cloud (vezi CLAUDE.md, „fără backend/cloud”). Ștergerea aplicației
/// șterge automat containerul ei de date pe iOS/Android; singura cale de a
/// păstra datele peste o reinstalare e ca utilizatorul să exporte manual un
/// fișier de backup (pe care îl salvează unde vrea — Files/iCloud
/// Drive/email etc., prin share sheet-ul telefonului) și să-l importe după
/// reinstalare.
///
/// Formatul e JSON (nu o copie brută a fișierului .db): conține toate
/// rândurile din tabelele de date ale utilizatorului, plus pozele/PDF-urile
/// atașate (`photoPath`) encodate base64 direct în același fișier — un
/// singur fișier autonom, fără nevoia unei librării de zip (evită o
/// dependință nouă și riscurile de compilare documentate în CLAUDE.md
/// pentru toolchain-ul Android/iOS al acestui proiect). La import,
/// `photoPath`-urile absolute din backup (care indică spre directorul
/// Documents al INSTALĂRII VECHI, cu alt path) sunt rescrise spre noul
/// director Documents, după ce fișierele sunt restaurate acolo cu același
/// nume de fișier.
///
/// Logica de (de)serializare (`exportBackupJson`/`importBackupJson`) e
/// separată de accesul la `path_provider` (`exportBackup`/`importBackup`),
/// la fel ca separarea `parseTalonText`/`scanTalon` din
/// `document_scanner_service.dart` — testabilă direct, cu un `Directory`
/// oarecare, fără să depindă de path_provider real.
class BackupService {
  BackupService._();

  static const formatVersion = 1;

  /// Tabelele cu date ale utilizatorului (nu tabelele de catalog static —
  /// `marci`/`modele`/`motoare`/etc. — regenerate la fiecare bump de
  /// versiune DB, nu sunt date de utilizator). Ordinea contează la
  /// restaurare: `vehicles` primul (părinte), restul după (au FK spre
  /// `vehicleId`).
  static const _tables = [
    'vehicles',
    'service_records',
    'car_documents',
    'reminders',
    'component_records',
    'vehicle_extra_components',
  ];

  /// Tabelele care au o coloană `photoPath` (poză sau PDF atașat).
  static const _tablesWithPhotoPath = ['vehicles', 'service_records', 'car_documents'];

  /// Construiește JSON-ul de backup dintr-o bază de date deja deschisă și un
  /// director de pe disc unde se caută fișierele referite de `photoPath`.
  static Future<String> exportBackupJson(Database db, Directory documentsDir) async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      tables[table] = await db.query(table);
    }

    final attachments = <String, String>{};
    for (final table in _tablesWithPhotoPath) {
      for (final row in tables[table]!) {
        final photoPath = row['photoPath'] as String?;
        if (photoPath == null) continue;
        final file = File(photoPath);
        if (!await file.exists()) continue;
        final basename = p.basename(photoPath);
        if (attachments.containsKey(basename)) continue;
        attachments[basename] = base64Encode(await file.readAsBytes());
      }
    }

    return jsonEncode({
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
      'attachments': attachments,
    });
  }

  /// Restaurează backup-ul: șterge datele existente ale utilizatorului (NU
  /// tabelele de catalog) și le înlocuiește cu cele din `jsonString`.
  /// Rescrie `photoPath`-urile ca să indice spre fișierele restaurate în
  /// `documentsDir`. Aruncă `FormatException` dacă JSON-ul nu arată ca un
  /// backup valid al acestei aplicații.
  static Future<void> importBackupJson(
    Database db,
    String jsonString,
    Directory documentsDir,
  ) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map || decoded['tables'] is! Map) {
      throw const FormatException('Fișierul nu pare a fi un backup CarPlanner valid.');
    }
    final tables = (decoded['tables'] as Map).cast<String, dynamic>();
    final attachments = (decoded['attachments'] as Map?)?.cast<String, dynamic>() ?? {};

    // Restaurează fișierele atașate ÎNAINTE de a rescrie photoPath, ca să
    // putem verifica pe disc dacă un anumit basename chiar există.
    final restoredBasenames = <String>{};
    for (final entry in attachments.entries) {
      final bytes = base64Decode(entry.value as String);
      final target = File(p.join(documentsDir.path, entry.key));
      await target.writeAsBytes(bytes);
      restoredBasenames.add(entry.key);
    }

    await db.transaction((txn) async {
      // Șterse explicit, copii înainte de părinți — nu ne bazăm doar pe
      // `ON DELETE CASCADE` (reminders/car_documents pot avea `vehicleId`
      // NULL, deci nu ar fi șterse prin cascadă de la `vehicles`).
      for (final table in _tables.reversed) {
        await txn.delete(table);
      }

      for (final table in _tables) {
        final rows = (tables[table] as List?)?.cast<dynamic>() ?? const [];
        for (final rawRow in rows) {
          final row = (rawRow as Map).cast<String, Object?>();
          if (_tablesWithPhotoPath.contains(table) && row['photoPath'] is String) {
            final basename = p.basename(row['photoPath'] as String);
            row['photoPath'] =
                restoredBasenames.contains(basename) ? p.join(documentsDir.path, basename) : null;
          }
          await txn.insert(table, row);
        }
      }
    });
  }

  /// Exportă un fișier de backup într-un director temporar, gata de trimis
  /// prin share sheet (`share_plus`, apelat din UI — vezi
  /// `settings_screen.dart`).
  static Future<File> exportBackup() async {
    final db = await DatabaseHelper.instance.database;
    final documentsDir = await getApplicationDocumentsDirectory();
    final json = await exportBackupJson(db, documentsDir);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final file = File(p.join(tempDir.path, 'carplanner_backup_$timestamp.json'));
    await file.writeAsString(json);
    return file;
  }

  /// Importă backup-ul dintr-un fișier ales de utilizator (`file_picker`,
  /// apelat din UI). ÎNLOCUIEȘTE toate datele existente — apelantul trebuie
  /// să confirme explicit cu utilizatorul înainte (acțiune ireversibilă).
  static Future<void> importBackup(File backupFile) async {
    final db = await DatabaseHelper.instance.database;
    final documentsDir = await getApplicationDocumentsDirectory();
    final json = await backupFile.readAsString();
    await importBackupJson(db, json, documentsDir);
  }
}
