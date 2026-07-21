import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/car_document.dart';
import '../models/component_record.dart';
import '../models/reminder.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../utils/vehicle_reference_data.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'car_planner.db');
    return openDatabase(
      path,
      version: 8,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createComponentRecordsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE service_records ADD COLUMN changedComponentIds TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalKm INTEGER');
      await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalMonths INTEGER');
      await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalSource TEXT');
      await _createVehicleExtraComponentsTable(db);
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE vehicles ADD COLUMN engineCode TEXT');
    }
    if (oldVersion < 6) {
      // v6 a introdus un prim set de tabele de catalog (vehicle_models/
      // maintenance_intervals); v7 le-a înlocuit complet cu schema
      // relațională de mai jos — dacă cineva a apucat să treacă prin v6,
      // le ștergem aici ca să nu rămână tabele orfane nefolosite.
      await db.execute('DROP TABLE IF EXISTS vehicle_models');
      await db.execute('DROP TABLE IF EXISTS maintenance_intervals');
    }
    if (oldVersion < 7) {
      await db.execute('DROP TABLE IF EXISTS vehicle_models');
      await db.execute('DROP TABLE IF EXISTS maintenance_intervals');
      await db.execute('DROP VIEW IF EXISTS mentenanta_completa');
      await db.execute('DROP TABLE IF EXISTS intervale_mentenanta');
      await db.execute('DROP TABLE IF EXISTS intervale_generice');
      await db.execute('DROP TABLE IF EXISTS componente');
      await db.execute('DROP TABLE IF EXISTS motoare');
      await db.execute('DROP TABLE IF EXISTS modele');
      await db.execute('DROP TABLE IF EXISTS marci');
      await _seedReferenceData(db);
    }
    if (oldVersion < 8) {
      // v8 înlocuiește integral catalogul cu `auto_mentenanta_3.sql` (18
      // mărci / 153 modele / 256 motorizări, față de 18/60/91 în v7) — doar
      // date noi, schema tabelelor e neschimbată. Drop necondiționat +
      // reseed, la fel ca la v7, ca id-urile auto-increment să pornească
      // curat de la 1 și să corespundă exact numerelor din
      // `vehicle_reference_data.dart`.
      await db.execute('DROP VIEW IF EXISTS mentenanta_completa');
      await db.execute('DROP TABLE IF EXISTS intervale_mentenanta');
      await db.execute('DROP TABLE IF EXISTS intervale_generice');
      await db.execute('DROP TABLE IF EXISTS componente');
      await db.execute('DROP TABLE IF EXISTS motoare');
      await db.execute('DROP TABLE IF EXISTS modele');
      await db.execute('DROP TABLE IF EXISTS marci');
      await _seedReferenceData(db);
    }
  }

  /// Tabele de catalog (nu de utilizator) — schema relațională
  /// marci→modele→motoare cu intervale de mentenanță, portată din SQL
  /// furnizat de utilizator (sursă declarată). Vezi
  /// `lib/utils/vehicle_reference_data.dart` pentru schema completă și
  /// datele în sine — sigur de recreat integral la fiecare bump de versiune
  /// (sunt date de catalog, nu date introduse de utilizator pe mașinile lui).
  Future<void> _seedReferenceData(Database db) async {
    for (final statement in referenceDataStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _createVehicleExtraComponentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_extra_components (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        componentId TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vehicle_extra_components_vehicle ON vehicle_extra_components (vehicleId)',
    );
  }

  Future<void> _createComponentRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS component_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        componentId TEXT NOT NULL,
        lastChangedDate TEXT,
        lastChangedMileage INTEGER,
        notes TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_component_records_vehicle ON component_records (vehicleId)',
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        plateNumber TEXT NOT NULL,
        vin TEXT,
        fuelType TEXT,
        engineCode TEXT,
        mileage INTEGER NOT NULL DEFAULT 0,
        photoPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        cost REAL,
        workshop TEXT,
        nextServiceDate TEXT,
        nextServiceMileage INTEGER,
        photoPath TEXT,
        changedComponentIds TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE car_documents (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        type TEXT NOT NULL,
        title TEXT,
        provider TEXT,
        policyNumber TEXT,
        startDate TEXT,
        expiryDate TEXT NOT NULL,
        cost REAL,
        notes TEXT,
        photoPath TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        vehicleId TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_service_vehicle ON service_records (vehicleId)');
    await db.execute('CREATE INDEX idx_documents_vehicle ON car_documents (vehicleId)');
    await db.execute('CREATE INDEX idx_reminders_vehicle ON reminders (vehicleId)');

    await _createComponentRecordsTable(db);
    // `_createComponentRecordsTable` builds the original (v2) schema so it can
    // be reused by the oldVersion<2 upgrade path — apply the later deltas on
    // top here too, same as a real upgrade would.
    await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalKm INTEGER');
    await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalMonths INTEGER');
    await db.execute('ALTER TABLE component_records ADD COLUMN customIntervalSource TEXT');
    await _createVehicleExtraComponentsTable(db);
    await _seedReferenceData(db);
  }

  // ---------- Vehicles ----------

  Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.insert(
      'vehicles',
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(String id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'createdAt DESC');
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getVehicle(String id) async {
    final db = await database;
    final rows = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Vehicle.fromMap(rows.first);
  }

  // ---------- Service records ----------

  Future<void> insertServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.insert(
      'service_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.update(
      'service_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteServiceRecord(String id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ServiceRecord>> getServiceRecords(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'service_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<List<ServiceRecord>> getAllServiceRecords() async {
    final db = await database;
    final rows = await db.query('service_records', orderBy: 'date DESC');
    return rows.map(ServiceRecord.fromMap).toList();
  }

  // ---------- Documents ----------

  Future<void> insertDocument(CarDocument document) async {
    final db = await database;
    await db.insert(
      'car_documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocument(CarDocument document) async {
    final db = await database;
    await db.update(
      'car_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete('car_documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CarDocument>> getDocumentsForVehicle(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'car_documents',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'expiryDate ASC',
    );
    return rows.map(CarDocument.fromMap).toList();
  }

  /// Documente fără mașină asociată (ex: asigurarea locuinței).
  Future<List<CarDocument>> getStandaloneDocuments() async {
    final db = await database;
    final rows = await db.query(
      'car_documents',
      where: 'vehicleId IS NULL',
      orderBy: 'expiryDate ASC',
    );
    return rows.map(CarDocument.fromMap).toList();
  }

  Future<List<CarDocument>> getAllDocuments() async {
    final db = await database;
    final rows = await db.query('car_documents', orderBy: 'expiryDate ASC');
    return rows.map(CarDocument.fromMap).toList();
  }

  // ---------- Reminders ----------

  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final rows = await db.query('reminders', orderBy: 'date ASC');
    return rows.map(Reminder.fromMap).toList();
  }

  // ---------- Component records ----------

  Future<void> upsertComponentRecord(ComponentRecord record) async {
    final db = await database;
    await db.insert(
      'component_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ComponentRecord>> getComponentRecords(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'component_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    return rows.map(ComponentRecord.fromMap).toList();
  }

  // ---------- Vehicle extra components ----------

  /// Leagă o componentă din `extraComponentCatalog` de o mașină anume — apare
  /// apoi în tabul Componente pentru mașina respectivă, deși nu face parte
  /// din lista esențială implicită.
  Future<void> addExtraComponent(String vehicleId, String componentId) async {
    final db = await database;
    await db.insert(
      'vehicle_extra_components',
      {'id': '${vehicleId}_$componentId', 'vehicleId': vehicleId, 'componentId': componentId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<String>> getExtraComponentIds(String vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'vehicle_extra_components',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
    return rows.map((r) => r['componentId'] as String).toSet();
  }

  // ---------- Reference data (cod motor → marcă/model/motor/intervale) ----------

  /// Primul motor de referință care folosește [engineCode] (poate exista mai
  /// mult de unul — același cod scurt apare uneori la mărci/modele diferite
  /// cu specificații ușor diferite; luăm primul, e doar pentru afișare și
  /// pentru a rezolva intervalele lui). `null` dacă nu are nicio potrivire.
  Future<Map<String, Object?>?> getEngineForCode(String? engineCode) async {
    if (engineCode == null) return null;
    final key = normalizeEngineCode(engineCode);
    if (key.isEmpty) return null;
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT mt.*, mo.nume AS model_nume, mo.generatie AS model_generatie, ma.nume AS marca_nume
      FROM motoare mt
      JOIN modele mo ON mo.id = mt.model_id
      JOIN marci ma ON ma.id = mo.marca_id
      WHERE mt.cod_motor_key = ?
      ORDER BY mt.id
      LIMIT 1
    ''', [key]);
    return rows.isEmpty ? null : rows.first;
  }

  /// Toate rândurile din view-ul `mentenanta_completa` pentru motorul
  /// [motorId] — combină automat regula specifică motorului (mai ales
  /// distribuție) cu fallback-ul generic pe combustibil pentru rest.
  Future<List<Map<String, Object?>>> getMaintenanceIntervalsForMotorId(int motorId) async {
    final db = await database;
    return db.rawQuery('SELECT * FROM mentenanta_completa WHERE motor_id = ?', [motorId]);
  }

  /// Motoare candidate din catalog pentru decodarea VIN: filtrează pe marcă
  /// (obligatoriu), opțional pe model (potrivire parțială, insensibilă la
  /// majuscule) și pe anul de fabricație (în intervalul `an_start`/`an_stop`
  /// al modelului). Nu decodifică motorul direct din caracterele VIN — doar
  /// restrânge catalogul existent la ce e plauzibil pentru marca/anul găsite,
  /// utilizatorul alegând motorul exact din listă. `null`/gol dacă [marca]
  /// lipsește.
  Future<List<Map<String, Object?>>> getCandidateEnginesForVin({
    String? marca,
    String? model,
    int? year,
    bool matchYear = true,
    bool matchModel = true,
  }) async {
    if (marca == null || marca.trim().isEmpty) return [];
    final db = await database;
    final where = StringBuffer('LOWER(ma.nume) = ?');
    final args = <Object?>[marca.trim().toLowerCase()];
    if (matchModel && model != null && model.trim().isNotEmpty) {
      where.write(' AND LOWER(mo.nume) LIKE ?');
      args.add('%${model.trim().toLowerCase()}%');
    }
    if (matchYear && year != null) {
      where.write(' AND (mo.an_start IS NULL OR mo.an_start <= ?)');
      args.add(year);
      where.write(' AND (mo.an_stop IS NULL OR mo.an_stop >= ?)');
      args.add(year);
    }
    return db.rawQuery('''
      SELECT mt.*, mo.nume AS model_nume, mo.generatie AS model_generatie, ma.nume AS marca_nume
      FROM motoare mt
      JOIN modele mo ON mo.id = mt.model_id
      JOIN marci ma ON ma.id = mo.marca_id
      WHERE $where
      ORDER BY mo.nume, mt.denumire_comerciala
    ''', args);
  }
}
