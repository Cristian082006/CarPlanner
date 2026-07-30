import 'package:car_planner/db/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Teste de regresie pe catalogul consolidat (v15): un singur rând per
/// nameplate în `modele`, deci căutarea pe marcă+model+an trebuie să
/// întoarcă TOATE motorizările modelului, indiferent de generație.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.clearInstance();
    await deleteDatabase('car_planner.db');
  });

  test('Ford Fiesta returnează toate motorizările, indiferent de an', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    for (final year in [2008, 2012, 2018]) {
      final engines = await dbHelper.getCandidateEnginesForVin(
        marca: 'Ford',
        model: 'Fiesta',
        year: year,
      );
      expect(engines.length, 16, reason: 'an $year');
    }
  });

  test('Codurile reale Fiesta 1.6 TDCi (v13) au supraviețuit portării v15',
      () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    for (final code in ['HHJC', 'HHJD', 'HHJE', 'TZJA', 'TZJB', 'T1JA', 'UBJA']) {
      final engine = await dbHelper.getEngineForCode(code);
      expect(engine, isNotNull, reason: code);
      final intervals =
          await dbHelper.getMaintenanceIntervalsForMotorId(engine!['id'] as int);
      expect(intervals, isNotEmpty, reason: code);
      final distributie = intervals.where(
          (r) => (r['componenta'] as String).startsWith('Curea/lant'));
      expect(distributie.single['sursa_regula'], 'Specific motor', reason: code);
    }
  });

  test('VW Golf și Polo returnează toate motorizările consolidate', () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    final golf = await dbHelper.getCandidateEnginesForVin(
        marca: 'Volkswagen', model: 'Golf', year: 2015);
    expect(golf.length, 8);

    final polo = await dbHelper.getCandidateEnginesForVin(
        marca: 'Volkswagen', model: 'Polo', year: 2010);
    expect(polo.length, 15); // 6 originale + 9 adăugate la v32
  });

  test(
      'BMW "420d" (denumire comercială a motorului) e găsit chiar dacă modelul din catalog e "Seria 4"',
      () async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database;

    // Bug real: utilizatorii completează modelul mașinii cu denumirea
    // comercială (420d), nu cu nameplate-ul din catalog (Seria 4) — căutarea
    // trebuie să verifice ambele coloane, nu doar modele.nume. Catalogul are
    // 2 motoare diesel cu denumirea comercială "420d" (N47D20 și B47D20, pre/
    // post 2020) — ambele trebuie găsite, spre deosebire de "Seria 4"
    // (nameplate-ul din catalog), care întoarce toate cele 4 motorizări
    // (2 diesel + 2 benzină).
    final byTrim = await dbHelper.getCandidateEnginesForVin(
        marca: 'BMW', model: '420d', year: 2015);
    expect(byTrim.map((e) => e['cod_motor']).toSet(), {'N47D20', 'B47D20'});

    final byNameplate = await dbHelper.getCandidateEnginesForVin(
        marca: 'BMW', model: 'Seria 4', year: 2015);
    expect(byNameplate.length, 4);
  });
}
