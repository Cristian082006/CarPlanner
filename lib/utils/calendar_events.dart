import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/reminder.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import 'alerts.dart';
import 'constants.dart';

/// Un eveniment cu dată fixă afișat în tabul Calendar — expirare document,
/// revizie programată sau reminder personal.
class CalendarEvent {
  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? vehicleId;
  final Reminder? reminder;

  CalendarEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.vehicleId,
    this.reminder,
  });
}

List<CalendarEvent> buildCalendarEvents({
  required List<CarDocument> documents,
  required List<ServiceRecord> serviceRecords,
  required List<Reminder> reminders,
  required Map<String, Vehicle> vehiclesById,
}) {
  final events = <CalendarEvent>[];

  for (final doc in documents) {
    final vehicleLabel =
        doc.vehicleId != null ? vehiclesById[doc.vehicleId]?.name ?? S.deletedCar : S.homeLabel;
    events.add(CalendarEvent(
      date: doc.expiryDate,
      title: doc.title?.isNotEmpty == true ? doc.title! : doc.type.label,
      subtitle: vehicleLabel,
      icon: doc.type.icon,
      color: colorForDays(doc.daysUntilExpiry),
      vehicleId: doc.vehicleId,
    ));
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final record in serviceRecords) {
    final due = record.nextServiceDate;
    if (due == null) continue;
    final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
    events.add(CalendarEvent(
      date: due,
      title: S.scheduledService,
      subtitle: vehiclesById[record.vehicleId]?.name ?? S.deletedCar,
      icon: Icons.build_outlined,
      color: colorForDays(days),
      vehicleId: record.vehicleId,
    ));
  }

  for (final reminder in reminders) {
    events.add(CalendarEvent(
      date: reminder.date,
      title: reminder.title,
      subtitle: reminder.vehicleId != null
          ? vehiclesById[reminder.vehicleId]?.name ?? S.deletedCar
          : S.reminder,
      icon: Icons.alarm_outlined,
      color: Colors.blueGrey,
      vehicleId: reminder.vehicleId,
      reminder: reminder,
    ));
  }

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}
