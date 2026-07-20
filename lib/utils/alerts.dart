import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import 'constants.dart';

/// O atenționare unificată, derivată fie dintr-un document (expirare),
/// fie dintr-o revizie programată.
class AlertItem {
  final String title;
  final String subtitle;
  final DateTime date;
  final int daysUntil;
  final IconData icon;
  final Color color;
  final String? vehicleId;

  AlertItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.daysUntil,
    required this.icon,
    required this.color,
    this.vehicleId,
  });
}

Color colorForDays(int days) {
  if (days < 0) return kDangerColor;
  if (days <= 30) return kWarningColor;
  return kOkColor;
}

List<AlertItem> buildAlerts({
  required List<CarDocument> documents,
  required List<ServiceRecord> serviceRecords,
  required Map<String, Vehicle> vehiclesById,
}) {
  final alerts = <AlertItem>[];

  for (final doc in documents) {
    final vehicleLabel = doc.vehicleId != null
        ? vehiclesById[doc.vehicleId]?.name ?? S.deletedCar
        : S.homeLabel;
    alerts.add(AlertItem(
      title: doc.title?.isNotEmpty == true ? doc.title! : doc.type.label,
      subtitle: vehicleLabel,
      date: doc.expiryDate,
      daysUntil: doc.daysUntilExpiry,
      icon: doc.type.icon,
      color: colorForDays(doc.daysUntilExpiry),
      vehicleId: doc.vehicleId,
    ));
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final record in serviceRecords) {
    if (record.nextServiceDate == null) continue;
    final due = record.nextServiceDate!;
    final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
    final vehicleLabel = vehiclesById[record.vehicleId]?.name ?? S.deletedCar;
    alerts.add(AlertItem(
      title: S.scheduledService,
      subtitle: vehicleLabel,
      date: due,
      daysUntil: days,
      icon: Icons.build_outlined,
      color: colorForDays(days),
      vehicleId: record.vehicleId,
    ));
  }

  alerts.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  return alerts;
}
