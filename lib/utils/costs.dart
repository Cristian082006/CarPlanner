import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import 'constants.dart';

/// O cheltuială individuală, derivată fie dintr-o revizie, fie dintr-un
/// document — orice rând cu `cost` completat și > 0.
class CostEntry {
  final String title;
  final String vehicleLabel;
  final DateTime date;
  final double amount;
  final IconData icon;
  final String? vehicleId;

  CostEntry({
    required this.title,
    required this.vehicleLabel,
    required this.date,
    required this.amount,
    required this.icon,
    this.vehicleId,
  });
}

/// Totalul cheltuielilor pentru o mașină (sau pentru „Casă”, `vehicleId == null`).
class CostGroup {
  final String label;
  final String? vehicleId;
  final List<CostEntry> entries;

  CostGroup({required this.label, required this.vehicleId, required this.entries});

  double get total => entries.fold(0, (sum, e) => sum + e.amount);
}

List<CostEntry> buildCostEntries({
  required List<CarDocument> documents,
  required List<ServiceRecord> serviceRecords,
  required Map<String, Vehicle> vehiclesById,
}) {
  final entries = <CostEntry>[];

  for (final record in serviceRecords) {
    final cost = record.cost;
    if (cost == null || cost <= 0) continue;
    entries.add(CostEntry(
      title: record.title,
      vehicleLabel: vehiclesById[record.vehicleId]?.name ?? S.deletedCar,
      date: record.date,
      amount: cost,
      icon: Icons.build_outlined,
      vehicleId: record.vehicleId,
    ));
  }

  for (final doc in documents) {
    final cost = doc.cost;
    if (cost == null || cost <= 0) continue;
    final vehicleLabel =
        doc.vehicleId != null ? vehiclesById[doc.vehicleId]?.name ?? S.deletedCar : S.homeLabel;
    entries.add(CostEntry(
      title: doc.title?.isNotEmpty == true ? doc.title! : doc.type.label,
      vehicleLabel: vehicleLabel,
      date: doc.startDate ?? doc.expiryDate,
      amount: cost,
      icon: doc.type.icon,
      vehicleId: doc.vehicleId,
    ));
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

List<CostGroup> groupCostsByVehicle(List<CostEntry> entries) {
  final byKey = <String, List<CostEntry>>{};
  final labelByKey = <String, String>{};
  for (final e in entries) {
    final key = e.vehicleId ?? '__house__';
    byKey.putIfAbsent(key, () => []).add(e);
    labelByKey[key] = e.vehicleLabel;
  }
  final groups = byKey.entries
      .map((e) => CostGroup(
            label: labelByKey[e.key]!,
            vehicleId: e.key == '__house__' ? null : e.key,
            entries: e.value,
          ))
      .toList();
  groups.sort((a, b) => b.total.compareTo(a.total));
  return groups;
}
