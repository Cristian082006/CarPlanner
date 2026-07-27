import 'package:car_planner/db/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresie: mărci înrudite pe platforme comune (VW/Seat) partajează
/// literalmente aceleași coduri de motor în catalog (ex. CFWA/CHZC/DKRF
/// apar atât la Volkswagen Polo cât și la Seat Ibiza). Fără marcă/model,
/// `getEngineForCode` lua orbește primul rând din catalog după `id`, iar
/// rândurile Ibiza au id-uri mai mici decât cele Polo — un Polo cu unul
/// din aceste coduri primea din greșeală profilul de mentenanță al unui
/// Seat Ibiza. Bug real reprodus și raportat de utilizator.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.clearInstance();
    await deleteDatabase('car_planner.db');
  });

  test('getEngineForCode preferă marca/modelul mașinii pentru un cod motor partajat',
      () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    for (final code in ['CFWA', 'CHZC', 'DKRF']) {
      final polo = await dbHelper.getEngineForCode(code, make: 'Volkswagen', model: 'Polo');
      expect(polo?['marca_nume'], 'Volkswagen', reason: code);
      expect(polo?['model_nume'], 'Polo', reason: code);

      final ibiza = await dbHelper.getEngineForCode(code, make: 'Seat', model: 'Ibiza');
      expect(ibiza?['marca_nume'], 'Seat', reason: code);
      expect(ibiza?['model_nume'], 'Ibiza', reason: code);
    }
  });

  test('fără marcă/model, getEngineForCode tot întoarce o potrivire validă (fallback)',
      () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final engine = await dbHelper.getEngineForCode('CFWA');
    expect(engine, isNotNull);
    expect(engine!['cod_motor_key'], 'CFWA');
  });

  /// Scanează TOT catalogul (nu doar Polo/Ibiza) — orice `cod_motor_key`
  /// partajat între mărci/modele diferite trebuie să se rezolve la marca+
  /// modelul cerut, pentru fiecare combinație în care apare acel cod.
  test('getEngineForCode rezolvă corect toate codurile de motor partajate din catalog',
      () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final rows = await db.rawQuery('''
      SELECT mt.cod_motor_key, ma.nume AS marca_nume, mo.nume AS model_nume
      FROM motoare mt
      JOIN modele mo ON mo.id = mt.model_id
      JOIN marci ma ON ma.id = mo.marca_id
      WHERE mt.cod_motor_key IS NOT NULL AND mt.cod_motor_key != ''
    ''');

    final byKey = <String, Set<String>>{};
    for (final r in rows) {
      final key = r['cod_motor_key'] as String;
      byKey.putIfAbsent(key, () => {}).add('${r['marca_nume']}|${r['model_nume']}');
    }

    for (final entry in byKey.entries) {
      if (entry.value.length < 2) continue; // nu e ambiguu, nimic de verificat
      for (final makeModel in entry.value) {
        final parts = makeModel.split('|');
        final marca = parts[0];
        final model = parts[1];
        final resolved = await dbHelper.getEngineForCode(entry.key, make: marca, model: model);
        expect(resolved?['marca_nume'], marca, reason: '${entry.key} → $marca/$model');
        expect(resolved?['model_nume'], model, reason: '${entry.key} → $marca/$model');
      }
    }
  });
}
