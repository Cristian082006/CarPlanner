import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/reminder.dart';
import '../models/service_record.dart';
import '../utils/constants.dart';

/// Gestionează notificările locale pentru remindere: expirare documente
/// (RCA, CASCO, rovinietă, ITP, asigurare locuință), revizii programate
/// și remindere manuale.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
    } catch (_) {
      // Dacă locația nu poate fi determinată, rămânem pe UTC.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  int _idFor(String sourceId, int variant) {
    final base = sourceId.hashCode & 0x7fffffff;
    return (base % 900000) * 10 + variant;
  }

  Future<void> _scheduleAt(
    int id,
    String title,
    String body,
    DateTime when,
  ) async {
    if (when.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'car_planner_reminders',
            S.notificationChannelName,
            channelDescription: S.notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // O notificare care nu poate fi programată nu trebuie să blocheze
      // salvarea datelor utilizatorului (ex: cache de notificări corupt).
    }
  }

  DateTime _atNine(DateTime date) =>
      DateTime(date.year, date.month, date.day, 9);

  /// Programează notificări pentru un document (la fiecare interval din
  /// [reminderLeadDays] înainte de expirare, plus în ziua expirării).
  Future<void> scheduleDocumentReminders(
    CarDocument document,
    String vehicleLabel,
  ) async {
    await cancelForDocument(document.id);
    final label = document.type.label;

    for (var i = 0; i < reminderLeadDays.length; i++) {
      final leadDays = reminderLeadDays[i];
      final fireDate = document.expiryDate.subtract(Duration(days: leadDays));
      await _scheduleAt(
        _idFor(document.id, i),
        S.documentExpiresInDays(label, leadDays),
        S.documentExpiresInDaysBody(label, vehicleLabel, _fmt(document.expiryDate)),
        _atNine(fireDate),
      );
    }

    await _scheduleAt(
      _idFor(document.id, reminderLeadDays.length),
      S.documentExpiresToday(label),
      S.documentExpiresTodayBody(label, vehicleLabel),
      _atNine(document.expiryDate),
    );
  }

  Future<void> cancelForDocument(String documentId) async {
    for (var i = 0; i <= reminderLeadDays.length; i++) {
      await _cancel(_idFor(documentId, i));
    }
  }

  /// Programează un reminder pentru următoarea revizie programată.
  Future<void> scheduleServiceReminder(
    ServiceRecord record,
    String vehicleLabel,
  ) async {
    await cancelForServiceRecord(record.id);
    if (record.nextServiceDate == null) return;

    await _scheduleAt(
      _idFor(record.id, 0),
      S.serviceDueSoonTitle,
      S.serviceDueSoonBody(vehicleLabel, _fmt(record.nextServiceDate!)),
      _atNine(record.nextServiceDate!.subtract(const Duration(days: 7))),
    );
    await _scheduleAt(
      _idFor(record.id, 1),
      S.serviceDueTodayTitle,
      S.serviceDueTodayBody(vehicleLabel),
      _atNine(record.nextServiceDate!),
    );
  }

  Future<void> cancelForServiceRecord(String recordId) async {
    await _cancel(_idFor(recordId, 0));
    await _cancel(_idFor(recordId, 1));
  }

  Future<void> scheduleCustomReminder(Reminder reminder) async {
    await cancelForReminder(reminder.id);
    await _scheduleAt(
      _idFor(reminder.id, 0),
      reminder.title,
      reminder.notes?.isNotEmpty == true ? reminder.notes! : S.genericReminderBody,
      _atNine(reminder.date),
    );
  }

  Future<void> cancelForReminder(String reminderId) async {
    await _cancel(_idFor(reminderId, 0));
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {
      // Idem: nu lăsăm o eroare a plugin-ului de notificări să blocheze
      // ștergerea/salvarea datelor reale ale utilizatorului.
    }
  }

  String _fmt(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
