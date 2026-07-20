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
      version: 6,
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
      await _createReferenceDataTables(db);
      await _seedReferenceData(db);
    }
  }

  /// Tabele de catalog (nu de utilizator) — date pe cod motor introduse de
  /// utilizator (sursă declarată: Autodata), vezi `vehicle_reference_data.dart`.
  /// `engine_code_key` e o coloană calculată (cod motor normalizat: majuscule,
  /// fără spații/liniuțe/puncte) folosită la interogare, ca "K9K 872" scris în
  /// orice format să găsească rândul corect.
  Future<void> _createReferenceDataTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicle_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        generation TEXT,
        engine_code TEXT NOT NULL,
        engine_code_key TEXT NOT NULL,
        fuel_type TEXT NOT NULL,
        hp INTEGER NOT NULL,
        oil_capacity REAL NOT NULL,
        oil_spec TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vehicle_models_engine_code_key ON vehicle_models (engine_code_key)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maintenance_intervals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        engine_code TEXT NOT NULL,
        engine_code_key TEXT NOT NULL,
        component_name TEXT NOT NULL,
        interval_km INTEGER,
        interval_months INTEGER,
        description TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_maintenance_intervals_engine_code_key ON maintenance_intervals (engine_code_key)',
    );
  }

  /// Date de catalog, nu date de utilizator — sigur de golit și reintrodus
  /// integral la fiecare bump de versiune (nu se pierde nimic din ce a
  /// introdus utilizatorul pe mașinile lui, doar catalogul de referință).
  Future<void> _seedReferenceData(Database db) async {
    await db.delete('vehicle_models');
    await db.delete('maintenance_intervals');

    final batch = db.batch();
    for (final row in vehicleModelRows) {
      batch.insert('vehicle_models', {
        'brand': row.brand,
        'model': row.model,
        'generation': row.generation,
        'engine_code': row.engineCode,
        'engine_code_key': normalizeEngineCode(row.engineCode),
        'fuel_type': row.fuelType,
        'hp': row.hp,
        'oil_capacity': row.oilCapacity,
        'oil_spec': row.oilSpec,
      });
    }
    for (final row in maintenanceIntervalRows) {
      batch.insert('maintenance_intervals', {
        'engine_code': row.engineCode,
        'engine_code_key': normalizeEngineCode(row.engineCode),
        'component_name': row.componentName,
        'interval_km': row.intervalKm,
        'interval_months': row.intervalMonths,
        'description': row.description,
      });
    }
    await batch.commit(noResult: true);
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
    await _createReferenceDataTables(db);
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

  // ---------- Reference data (cod motor → intervale/model) ----------

  /// Toate rândurile de interval găsite pentru [engineCode] (poate fi mai
  /// multe — ulei, filtru combustibil, kit distribuție etc.). Listă goală
  /// dacă [engineCode] e null/gol sau nu are nicio potrivire.
  Future<List<Map<String, Object?>>> getMaintenanceIntervalsForEngineCode(String? engineCode) async {
    if (engineCode == null) return [];
    final key = normalizeEngineCode(engineCode);
    if (key.isEmpty) return [];
    final db = await database;
    return db.query('maintenance_intervals', where: 'engine_code_key = ?', whereArgs: [key]);
  }

  /// Primul vehicul de referință care folosește [engineCode] — folosit doar
  /// pentru afișare (marcă/model/generație, spec ulei), nu pentru intervale
  /// (acelea vin din `getMaintenanceIntervalsForEngineCode`).
  Future<Map<String, Object?>?> getVehicleModelForEngineCode(String? engineCode) async {
    if (engineCode == null) return null;
    final key = normalizeEngineCode(engineCode);
    if (key.isEmpty) return null;
    final db = await database;
    final rows = await db.query(
      'vehicle_models',
      where: 'engine_code_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}
