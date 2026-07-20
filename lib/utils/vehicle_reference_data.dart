/// Date de referință pe cod motor — introduse de utilizator (nu cercetate/
/// verificate de mine), sursă declarată: Autodata. Stocate ca tabele SQLite
/// (`vehicle_models`, `maintenance_intervals`), seedate la fiecare bump de
/// versiune DB din `database_helper.dart` — reseed complet (DELETE + INSERT),
/// fiindcă sunt date de catalog, nu date de utilizator.
///
/// Pentru actualizări viitoare: cere utilizatorului un export nou (SQL sau
/// listă structurată), înlocuiește listele de mai jos cu conținutul nou și
/// crește versiunea DB — nu edita rând cu rând din memorie, nu ai de unde
/// verifica valorile.
library;

/// Un rând din `vehicle_models`: ce mașină/motorizare folosește acest cod
/// de motor, ce ulei recomandă și ce cantitate.
class VehicleModelRow {
  final String brand;
  final String model;
  final String? generation;
  final String engineCode;
  final String fuelType;
  final int hp;
  final double oilCapacity;
  final String oilSpec;

  const VehicleModelRow({
    required this.brand,
    required this.model,
    this.generation,
    required this.engineCode,
    required this.fuelType,
    required this.hp,
    required this.oilCapacity,
    required this.oilSpec,
  });
}

/// Un rând din `maintenance_intervals`: intervalul pentru o componentă
/// anume, pe un cod de motor anume. `intervalMonths == 0` înseamnă "fără
/// limită pe timp" (ex. kit distribuție la unele motorizări).
class MaintenanceIntervalRow {
  final String engineCode;
  final String componentName;
  final int? intervalKm;
  final int? intervalMonths;
  final String? description;

  const MaintenanceIntervalRow({
    required this.engineCode,
    required this.componentName,
    this.intervalKm,
    this.intervalMonths,
    this.description,
  });
}

/// Normalizează un cod de motor (majuscule, fără spații/liniuțe/puncte) —
/// folosit atât la seed cât și la interogare, ca "K9K 872" introdus de
/// utilizator să găsească rândul stocat ca "K9K 872".
String normalizeEngineCode(String engineCode) {
  return engineCode.trim().toUpperCase().replaceAll(RegExp(r'[\s\-.]'), '');
}

const List<VehicleModelRow> vehicleModelRows = [
  // Hyundai / Kia
  VehicleModelRow(brand: 'Hyundai', model: 'Tucson', generation: 'TL (2015-2020)', engineCode: 'D4HA', fuelType: 'Diesel', hp: 184, oilCapacity: 7.6, oilSpec: 'ACEA C3 5W-30'),
  VehicleModelRow(brand: 'Hyundai', model: 'Tucson', generation: 'NX4 (2020+)', engineCode: 'D4FE', fuelType: 'Diesel', hp: 136, oilCapacity: 5.4, oilSpec: 'ACEA C5 0W-30'),
  VehicleModelRow(brand: 'Hyundai', model: 'i30', generation: 'PDE (2017-2024)', engineCode: 'G3LC', fuelType: 'Petrol', hp: 120, oilCapacity: 3.8, oilSpec: 'API SN 0W-20'),
  VehicleModelRow(brand: 'Kia', model: 'Sportage', generation: 'QL (2016-2021)', engineCode: 'D4HA', fuelType: 'Diesel', hp: 185, oilCapacity: 7.6, oilSpec: 'ACEA C3 5W-30'),
  VehicleModelRow(brand: 'Kia', model: 'Ceed', generation: 'CD (2018+)', engineCode: 'G4LD', fuelType: 'Petrol', hp: 140, oilCapacity: 4.2, oilSpec: 'API SN 0W-30'),

  // Volkswagen / Skoda / Audi / Seat
  VehicleModelRow(brand: 'Volkswagen', model: 'Golf VII', generation: 'Mk7 (2012-2020)', engineCode: 'CRLB', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Volkswagen', model: 'Golf VII', generation: 'Mk7 (2012-2020)', engineCode: 'CHPA', fuelType: 'Petrol', hp: 140, oilCapacity: 4.0, oilSpec: 'VW 504 00 5W-30'),
  VehicleModelRow(brand: 'Volkswagen', model: 'Passat B8', generation: 'B8 (2014-2023)', engineCode: 'DFCA', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Volkswagen', model: 'Tiguan', generation: 'AD1 (2016-2024)', engineCode: 'DFHA', fuelType: 'Diesel', hp: 190, oilCapacity: 5.5, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Skoda', model: 'Octavia', generation: 'Mk3 (2013-2020)', engineCode: 'CRLB', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Skoda', model: 'Octavia', generation: 'Mk4 (2020+)', engineCode: 'DTSB', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Skoda', model: 'Superb', generation: '3V (2015-2024)', engineCode: 'DFCA', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Audi', model: 'A4', generation: 'B9 (2015-2023)', engineCode: 'DEUA', fuelType: 'Diesel', hp: 150, oilCapacity: 5.0, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Audi', model: 'A6', generation: 'C8 (2018+)', engineCode: 'DFBA', fuelType: 'Diesel', hp: 204, oilCapacity: 6.1, oilSpec: 'VW 507 00 5W-30'),
  VehicleModelRow(brand: 'Seat', model: 'Leon', generation: '5F (2012-2020)', engineCode: 'CRLB', fuelType: 'Diesel', hp: 150, oilCapacity: 4.7, oilSpec: 'VW 507 00 5W-30'),

  // Dacia / Renault
  VehicleModelRow(brand: 'Dacia', model: 'Duster', generation: 'Duster II (2018-2024)', engineCode: 'K9K 872', fuelType: 'Diesel', hp: 115, oilCapacity: 4.8, oilSpec: 'RN17 5W-30'),
  VehicleModelRow(brand: 'Dacia', model: 'Duster', generation: 'Duster II (2018-2024)', engineCode: 'H5H', fuelType: 'Petrol', hp: 130, oilCapacity: 5.1, oilSpec: 'RN17 5W-30'),
  VehicleModelRow(brand: 'Dacia', model: 'Logan', generation: 'Logan III (2021+)', engineCode: 'H4D', fuelType: 'Petrol', hp: 90, oilCapacity: 4.1, oilSpec: 'RN17 0W-20'),
  VehicleModelRow(brand: 'Renault', model: 'Megane', generation: 'IV (2016-2024)', engineCode: 'K9K 646', fuelType: 'Diesel', hp: 110, oilCapacity: 4.5, oilSpec: 'RN0720 5W-30'),
  VehicleModelRow(brand: 'Renault', model: 'Kadjar', generation: 'HA (2015-2022)', engineCode: 'R9M', fuelType: 'Diesel', hp: 130, oilCapacity: 6.0, oilSpec: 'RN0720 5W-30'),

  // BMW
  VehicleModelRow(brand: 'BMW', model: '3er', generation: 'F30 (2012-2019)', engineCode: 'N47D20O1', fuelType: 'Diesel', hp: 184, oilCapacity: 5.2, oilSpec: 'BMW Longlife-04 5W-30'),
  VehicleModelRow(brand: 'BMW', model: '3er', generation: 'F30 LCI (2015-2019)', engineCode: 'B47D20', fuelType: 'Diesel', hp: 190, oilCapacity: 5.5, oilSpec: 'BMW Longlife-04 5W-30'),
  VehicleModelRow(brand: 'BMW', model: '5er', generation: 'G30 (2017-2023)', engineCode: 'B57D30A', fuelType: 'Diesel', hp: 265, oilCapacity: 6.5, oilSpec: 'BMW Longlife-04 5W-30'),
  VehicleModelRow(brand: 'BMW', model: 'X3', generation: 'F25 (2010-2017)', engineCode: 'N47D20', fuelType: 'Diesel', hp: 184, oilCapacity: 5.2, oilSpec: 'BMW Longlife-04 5W-30'),

  // Mercedes-Benz
  VehicleModelRow(brand: 'Mercedes-Benz', model: 'C-Class', generation: 'W205 (2014-2021)', engineCode: 'OM651', fuelType: 'Diesel', hp: 170, oilCapacity: 6.5, oilSpec: 'MB 229.51 5W-30'),
  VehicleModelRow(brand: 'Mercedes-Benz', model: 'C-Class', generation: 'W205 LCI (2018-2021)', engineCode: 'OM654', fuelType: 'Diesel', hp: 194, oilCapacity: 6.3, oilSpec: 'MB 229.52 5W-30'),
  VehicleModelRow(brand: 'Mercedes-Benz', model: 'E-Class', generation: 'W213 (2016-2023)', engineCode: 'OM654', fuelType: 'Diesel', hp: 194, oilCapacity: 6.3, oilSpec: 'MB 229.52 5W-30'),
  VehicleModelRow(brand: 'Mercedes-Benz', model: 'GLC', generation: 'X253 (2015-2022)', engineCode: 'OM651', fuelType: 'Diesel', hp: 170, oilCapacity: 6.5, oilSpec: 'MB 229.51 5W-30'),

  // Ford & Toyota
  VehicleModelRow(brand: 'Ford', model: 'Focus', generation: 'Mk3 (2011-2018)', engineCode: 'T3DA', fuelType: 'Diesel', hp: 95, oilCapacity: 4.1, oilSpec: 'WSS-M2C950-A 0W-30'),
  VehicleModelRow(brand: 'Ford', model: 'Focus', generation: 'Mk4 (2018-2024)', engineCode: 'YZDA', fuelType: 'Petrol', hp: 150, oilCapacity: 5.1, oilSpec: 'WSS-M2C948-B 5W-20'),
  VehicleModelRow(brand: 'Ford', model: 'Kuga', generation: 'Mk2 (2013-2019)', engineCode: 'T7MA', fuelType: 'Diesel', hp: 150, oilCapacity: 6.1, oilSpec: 'WSS-M2C950-A 0W-30'),
  VehicleModelRow(brand: 'Toyota', model: 'Corolla', generation: 'E210 (2019+)', engineCode: 'M20A-FXS', fuelType: 'Hybrid', hp: 184, oilCapacity: 4.3, oilSpec: 'API SP 0W-16'),
  VehicleModelRow(brand: 'Toyota', model: 'RAV4', generation: 'XA50 (2019+)', engineCode: 'A25A-FXS', fuelType: 'Hybrid', hp: 222, oilCapacity: 4.5, oilSpec: 'API SP 0W-16'),
];

const List<MaintenanceIntervalRow> maintenanceIntervalRows = [
  MaintenanceIntervalRow(engineCode: 'D4HA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Regim sever România'),
  MaintenanceIntervalRow(engineCode: 'D4HA', componentName: 'Filtru combustibil', intervalKm: 30000, intervalMonths: 24, description: 'Motorină'),
  MaintenanceIntervalRow(engineCode: 'D4FE', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Regim sever'),
  MaintenanceIntervalRow(engineCode: 'G3LC', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Benzină T-GDI'),
  MaintenanceIntervalRow(engineCode: 'CRLB', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Regim sever TDI'),
  MaintenanceIntervalRow(engineCode: 'CRLB', componentName: 'Kit distribuție (Curea + Pompă)', intervalKm: 210000, intervalMonths: 0, description: 'Limită producător'),
  MaintenanceIntervalRow(engineCode: 'CHPA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Benzină TSI'),
  MaintenanceIntervalRow(engineCode: 'DFCA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Regim sever'),
  MaintenanceIntervalRow(engineCode: 'DFHA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Tiguan 2.0 TDI'),
  MaintenanceIntervalRow(engineCode: 'DTSB', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Octavia 4 2.0 TDI'),
  MaintenanceIntervalRow(engineCode: 'DEUA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Audi A4 B9'),
  MaintenanceIntervalRow(engineCode: 'DFBA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Audi A6 C8'),
  MaintenanceIntervalRow(engineCode: 'K9K 872', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Dacia Duster dCi'),
  MaintenanceIntervalRow(engineCode: 'K9K 872', componentName: 'Kit distribuție', intervalKm: 150000, intervalMonths: 72, description: 'Curea și role'),
  MaintenanceIntervalRow(engineCode: 'H5H', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Duster TCe'),
  MaintenanceIntervalRow(engineCode: 'H4D', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Logan 1.0 TCe'),
  MaintenanceIntervalRow(engineCode: 'K9K 646', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Renault Megane dCi'),
  MaintenanceIntervalRow(engineCode: 'R9M', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Renault Kadjar dCi'),
  MaintenanceIntervalRow(engineCode: 'N47D20O1', componentName: 'Ulei motor și filtru', intervalKm: 12000, intervalMonths: 12, description: 'Recomandat preventiv lanț'),
  MaintenanceIntervalRow(engineCode: 'B47D20', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'BMW B47'),
  MaintenanceIntervalRow(engineCode: 'B57D30A', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'BMW 3.0d'),
  MaintenanceIntervalRow(engineCode: 'OM651', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Mercedes OM651'),
  MaintenanceIntervalRow(engineCode: 'OM654', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Mercedes OM654'),
  MaintenanceIntervalRow(engineCode: 'T3DA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Ford Focus 1.5 TDCi'),
  MaintenanceIntervalRow(engineCode: 'YZDA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Ford Focus 1.5 EcoBoost'),
  MaintenanceIntervalRow(engineCode: 'T7MA', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Ford Kuga 2.0 TDCi'),
  MaintenanceIntervalRow(engineCode: 'M20A-FXS', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Toyota Hybrid 2.0'),
  MaintenanceIntervalRow(engineCode: 'A25A-FXS', componentName: 'Ulei motor și filtru', intervalKm: 15000, intervalMonths: 12, description: 'Toyota RAV4 Hybrid'),
];
