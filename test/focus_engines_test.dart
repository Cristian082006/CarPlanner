import 'package:car_planner/db/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresie (v33): corectat M1DA (era greșit ca "1.6 Ti-VCT 105" în
/// exportul original — e de fapt 1.0 EcoBoost 125, confirmat de 5+ surse
/// independente) și adăugat M2DA (1.0 EcoBoost 100) pentru Ford Focus.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.clearInstance();
    await deleteDatabase('car_planner.db');
  });

  test('M1DA pe Focus e corectat la 1.0 EcoBoost 125 (nu 1.6 Ti-VCT 105)', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final engine = await dbHelper.getEngineForCode('M1DA', make: 'Ford', model: 'Focus');
    expect(engine, isNotNull);
    expect(engine!['model_nume'], 'Focus');
    expect(engine['capacitate_cm3'], 998);
    expect(engine['putere_cp'], 125);
    expect(engine['cilindri'], 3);
    expect(engine['combustibil'], 'Benzina');
  });

  test('M2DA pe Fiesta (deja existent) rămâne neafectat de adăugarea M2DA pe Focus', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final engine = await dbHelper.getEngineForCode('M2DA', make: 'Ford', model: 'Fiesta');
    expect(engine, isNotNull);
    expect(engine!['model_nume'], 'Fiesta');
    expect(engine['an_start'], 2017);
  });

  test('M2DA e nou adăugat pe Focus, 1.0 EcoBoost 100', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final engine = await dbHelper.getEngineForCode('M2DA', make: 'Ford', model: 'Focus');
    expect(engine, isNotNull);
    expect(engine!['capacitate_cm3'], 998);
    expect(engine['putere_cp'], 100);
    expect(engine['cilindri'], 3);
    expect(engine['combustibil'], 'Benzina');
  });
}
