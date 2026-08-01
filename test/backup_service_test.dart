import 'dart:convert';
import 'dart:io';

import 'package:car_planner/db/database_helper.dart';
import 'package:car_planner/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.clearInstance();
    await deleteDatabase('car_planner.db');
  });

  Map<String, Object?> vehicleRow({
    required String id,
    String? photoPath,
  }) =>
      {
        'id': id,
        'name': 'Mașina mea',
        'make': 'Dacia',
        'model': 'Logan',
        'year': 2015,
        'plateNumber': 'B123ABC',
        'vin': null,
        'fuelType': 'Diesel',
        'engineCode': null,
        'mileage': 50000,
        'photoPath': photoPath,
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
      };

  test('round trip: exports the attached photo and rewrites its path on import', () async {
    final db = await DatabaseHelper.instance.database;
    final oldDocsDir = await Directory.systemTemp.createTemp('carplanner_old_docs');
    final newDocsDir = await Directory.systemTemp.createTemp('carplanner_new_docs');
    addTearDown(() async {
      await oldDocsDir.delete(recursive: true);
      await newDocsDir.delete(recursive: true);
    });

    final oldPhotoPath = '${oldDocsDir.path}/attach_123.jpg';
    await File(oldPhotoPath).writeAsBytes([1, 2, 3, 4]);
    await db.insert('vehicles', vehicleRow(id: 'v1', photoPath: oldPhotoPath));

    final json = await BackupService.exportBackupJson(db, oldDocsDir);
    final decoded = jsonDecode(json) as Map;
    expect((decoded['attachments'] as Map).containsKey('attach_123.jpg'), isTrue);

    await BackupService.importBackupJson(db, json, newDocsDir);

    final rows = await db.query('vehicles');
    expect(rows, hasLength(1));
    final restoredPath = rows.single['photoPath'] as String;
    expect(restoredPath, '${newDocsDir.path}/attach_123.jpg');
    expect(await File(restoredPath).readAsBytes(), [1, 2, 3, 4]);
  });

  test('import replaces existing data instead of merging it', () async {
    final db = await DatabaseHelper.instance.database;
    final docsDir = await Directory.systemTemp.createTemp('carplanner_docs');
    addTearDown(() => docsDir.delete(recursive: true));

    await db.insert('vehicles', vehicleRow(id: 'from-backup'));
    final json = await BackupService.exportBackupJson(db, docsDir);

    // Simulate data added after the backup was taken (e.g. a fresh install
    // with a car already entered before the user remembers to import).
    await db.insert('vehicles', vehicleRow(id: 'added-after-export'));
    expect(await db.query('vehicles'), hasLength(2));

    await BackupService.importBackupJson(db, json, docsDir);

    final rows = await db.query('vehicles');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'from-backup');
  });

  test('drops a photoPath that points at a file missing from the backup instead of leaving a '
      'stale path from the old install', () async {
    final db = await DatabaseHelper.instance.database;
    final oldDocsDir = await Directory.systemTemp.createTemp('carplanner_old_docs');
    final newDocsDir = await Directory.systemTemp.createTemp('carplanner_new_docs');
    addTearDown(() async {
      await oldDocsDir.delete(recursive: true);
      await newDocsDir.delete(recursive: true);
    });

    // photoPath set on the row, but the file was never actually on disk
    // (or got deleted) when the export ran — exportBackupJson silently
    // skips it (see _tablesWithPhotoPath loop), so it never lands in
    // "attachments".
    await db.insert(
      'vehicles',
      vehicleRow(id: 'v1', photoPath: '${oldDocsDir.path}/missing.jpg'),
    );
    final json = await BackupService.exportBackupJson(db, oldDocsDir);

    await BackupService.importBackupJson(db, json, newDocsDir);

    final rows = await db.query('vehicles');
    expect(rows.single['photoPath'], isNull);
  });

  test('importBackupJson rejects a file that is not a CarPlanner backup', () async {
    final db = await DatabaseHelper.instance.database;
    final docsDir = await Directory.systemTemp.createTemp('carplanner_docs');
    addTearDown(() => docsDir.delete(recursive: true));

    expect(
      () => BackupService.importBackupJson(db, jsonEncode({'foo': 'bar'}), docsDir),
      throwsFormatException,
    );
  });

  test('exports and restores child rows (service records) linked to their vehicle', () async {
    final db = await DatabaseHelper.instance.database;
    final docsDir = await Directory.systemTemp.createTemp('carplanner_docs');
    addTearDown(() => docsDir.delete(recursive: true));

    await db.insert('vehicles', vehicleRow(id: 'v1'));
    await db.insert('service_records', {
      'id': 's1',
      'vehicleId': 'v1',
      'date': DateTime(2024, 6, 1).toIso8601String(),
      'mileage': 51000,
      'title': 'Schimb ulei',
      'description': null,
      'cost': 250.0,
      'workshop': null,
      'nextServiceDate': null,
      'nextServiceMileage': null,
      'photoPath': null,
      'changedComponentIds': null,
    });

    final json = await BackupService.exportBackupJson(db, docsDir);
    await BackupService.importBackupJson(db, json, docsDir);

    final serviceRows = await db.query('service_records');
    expect(serviceRows, hasLength(1));
    expect(serviceRows.single['vehicleId'], 'v1');
    expect(serviceRows.single['title'], 'Schimb ulei');
  });
}
