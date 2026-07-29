import 'package:car_planner/db/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Regresie (v32): 9 motorizări VW Polo cercetate și adăugate la cererea
/// utilizatorului (lipseau din catalogul consolidat) — verifică specificațiile
/// exacte, nu doar existența rândului, ca să prindă o eventuală greșeală de
/// tastare la capacitate/putere/combustibil.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.clearInstance();
    await deleteDatabase('car_planner.db');
  });

  test('cele 9 motorizări noi VW Polo au specificațiile corecte', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    const expected = {
      'ASY': (capacitate: 1896, putere: 64, combustibil: 'Diesel'),
      'BME': (capacitate: 1198, putere: 64, combustibil: 'Benzina'),
      'BNM': (capacitate: 1422, putere: 70, combustibil: 'Diesel'),
      'BTS': (capacitate: 1598, putere: 105, combustibil: 'Benzina'),
      'CFW': (capacitate: 1199, putere: 75, combustibil: 'Diesel'),
      'CAYC': (capacitate: 1598, putere: 90, combustibil: 'Diesel'),
      'CTHE': (capacitate: 1390, putere: 180, combustibil: 'Benzina'),
      'CHYA': (capacitate: 999, putere: 65, combustibil: 'Benzina'),
      'CHYB': (capacitate: 999, putere: 75, combustibil: 'Benzina'),
    };

    for (final entry in expected.entries) {
      final engine = await dbHelper.getEngineForCode(
        entry.key,
        make: 'Volkswagen',
        model: 'Polo',
      );
      expect(engine, isNotNull, reason: entry.key);
      expect(engine!['marca_nume'], 'Volkswagen', reason: entry.key);
      expect(engine['model_nume'], 'Polo', reason: entry.key);
      expect(engine['capacitate_cm3'], entry.value.capacitate, reason: entry.key);
      expect(engine['putere_cp'], entry.value.putere, reason: entry.key);
      expect(engine['combustibil'], entry.value.combustibil, reason: entry.key);
    }
  });

  test('Polo întoarce toate cele 15 motorizări (6 existente + 9 noi)', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final engines = await dbHelper.getCandidateEnginesForVin(
      marca: 'Volkswagen',
      model: 'Polo',
      year: 2020,
    );
    expect(engines.length, 15);
  });

  test('cele 4 motoare diesel noi (ASY/BNM/CFW/CAYC) au regula specifică de ulei 15000km/12luni',
      () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    for (final code in ['ASY', 'BNM', 'CFW', 'CAYC']) {
      final engine =
          await dbHelper.getEngineForCode(code, make: 'Volkswagen', model: 'Polo');
      expect(engine, isNotNull, reason: code);
      final intervals =
          await dbHelper.getMaintenanceIntervalsForMotorId(engine!['id'] as int);
      final ulei = intervals.where((r) => (r['componenta'] as String).startsWith('Ulei motor'));
      expect(ulei.single['interval_km'], 15000, reason: code);
      expect(ulei.single['interval_luni'], 12, reason: code);
      expect(ulei.single['sursa_regula'], 'Specific motor', reason: code);
    }
  });

  test('celelalte 5 motoare noi (BME/BTS/CTHE/CHYA/CHYB) rămân pe fallback-ul generic', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    for (final code in ['BME', 'BTS', 'CTHE', 'CHYA', 'CHYB']) {
      final engine =
          await dbHelper.getEngineForCode(code, make: 'Volkswagen', model: 'Polo');
      expect(engine, isNotNull, reason: code);
      final intervals =
          await dbHelper.getMaintenanceIntervalsForMotorId(engine!['id'] as int);
      final ulei = intervals.where((r) => (r['componenta'] as String).startsWith('Ulei motor'));
      expect(ulei.single['sursa_regula'], 'Regula generica', reason: code);
    }
  });
}
