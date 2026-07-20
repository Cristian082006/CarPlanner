import 'package:flutter_test/flutter_test.dart';
import 'package:car_planner/models/component_record.dart';
import 'package:car_planner/utils/vehicle_components.dart';

void main() {
  const oilDefinition = ComponentDefinition(
    id: 'engine_oil',
    intervalKm: 12000,
    intervalMonths: 12,
  );

  test('component with no record is unset', () {
    final status = computeComponentStatus(
      definition: oilDefinition,
      record: null,
      currentMileage: 50000,
    );
    expect(status, ComponentStatus.unset);
  });

  test('component well within interval is OK', () {
    final record = ComponentRecord(
      vehicleId: 'v1',
      componentId: 'engine_oil',
      lastChangedDate: DateTime.now().subtract(const Duration(days: 30)),
      lastChangedMileage: 40000,
    );
    final status = computeComponentStatus(
      definition: oilDefinition,
      record: record,
      currentMileage: 42000,
    );
    expect(status, ComponentStatus.ok);
  });

  test('component past the km interval is overdue', () {
    final record = ComponentRecord(
      vehicleId: 'v1',
      componentId: 'engine_oil',
      lastChangedDate: DateTime.now().subtract(const Duration(days: 30)),
      lastChangedMileage: 30000,
    );
    final status = computeComponentStatus(
      definition: oilDefinition,
      record: record,
      currentMileage: 43000,
    );
    expect(status, ComponentStatus.overdue);
  });

  test('component past the time interval is overdue even if mileage is low', () {
    final record = ComponentRecord(
      vehicleId: 'v1',
      componentId: 'engine_oil',
      lastChangedDate: DateTime.now().subtract(const Duration(days: 400)),
      lastChangedMileage: 30000,
    );
    final status = computeComponentStatus(
      definition: oilDefinition,
      record: record,
      currentMileage: 30500,
    );
    expect(status, ComponentStatus.overdue);
  });

  test('component close to the interval is due soon', () {
    final record = ComponentRecord(
      vehicleId: 'v1',
      componentId: 'engine_oil',
      lastChangedDate: DateTime.now().subtract(const Duration(days: 30)),
      lastChangedMileage: 30000,
    );
    final status = computeComponentStatus(
      definition: oilDefinition,
      record: record,
      currentMileage: 40500, // 10,500 / 12,000 = 87.5%
    );
    expect(status, ComponentStatus.dueSoon);
  });
}
