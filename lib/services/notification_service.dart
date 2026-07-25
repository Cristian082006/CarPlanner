import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/component_record.dart';
import '../models/reminder.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../utils/constants.dart';
import '../utils/vehicle_components.dart';

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

  /// Programează un reminder LUNAR recurent care încurajează utilizatorul să
  /// introducă kilometrajul curent — necesar fiindcă partea în km a
  /// intervalului componentelor nu se poate actualiza singură (spre
  /// deosebire de partea în luni, vezi `scheduleComponentReminder`): dacă
  /// utilizatorul nu mai deschide ecranul de editare a mașinii, statusul de
  /// km rămâne înghețat la ultima valoare salvată. Repetă în fiecare lună,
  /// în aceeași zi (ziua din `vehicle.createdAt`, limitată la 1-28 ca să
  /// existe în toate lunile) la ora 9, via `matchDateTimeComponents:
  /// dayOfMonthAndTime` — suportat nativ de plugin pe Android/iOS, nu
  /// necesită re-programare manuală lunară. Idempotent: apelabilă oricând
  /// (la creare mașină și la fiecare pornire a aplicației, ca reminder-ul să
  /// existe și pentru mașini adăugate înainte de această funcționalitate).
  Future<void> scheduleMileageReminder(Vehicle vehicle) async {
    final day = vehicle.createdAt.day.clamp(1, 28);
    final scheduled = _nextOccurrence(day, hour: 9);
    try {
      await _plugin.zonedSchedule(
        _idFor(vehicle.id, 900),
        S.mileageReminderTitle(vehicle.name),
        S.mileageReminderBody,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'car_planner_reminders',
            S.notificationChannelName,
            channelDescription: S.notificationChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (_) {
      // Idem restul serviciului: nu blocăm salvarea mașinii dacă
      // plugin-ul de notificări eșuează.
    }
  }

  Future<void> cancelMileageReminder(String vehicleId) async {
    await _cancel(_idFor(vehicleId, 900));
  }

  /// Prima aparitie viitoare a zilei [day] din lună, la ora [hour] — punctul
  /// de plecare pentru `matchDateTimeComponents: dayOfMonthAndTime` (care
  /// preia de-aici doar componentele zi/oră și repetă lunar).
  tz.TZDateTime _nextOccurrence(int day, {required int hour}) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(tz.local, now.year, now.month, day, hour);
    if (candidate.isBefore(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final year = now.month == 12 ? now.year + 1 : now.year;
      candidate = tz.TZDateTime(tz.local, year, nextMonth, day, hour);
    }
    return candidate;
  }

  /// Programează notificări (recomandat curând + depășit) pentru o
  /// componentă din tabul Componente, bazate STRICT pe partea în luni a
  /// intervalului (dată ultimei schimbări + interval) — partea în km nu
  /// poate fi programată dinainte, fiindcă nu știm când va ajunge
  /// utilizatorul la kilometrajul respectiv; aceea e verificată reactiv la
  /// fiecare actualizare de kilometraj, vezi `checkComponentStatuses`.
  /// Apelată din toate locurile care fac `upsertComponentRecord` (ecranul de
  /// editare componentă, bifele de la o revizie, aplicarea unui profil de
  /// mentenanță) — dacă nu are dată sau interval în luni, doar anulează
  /// orice notificare programată anterior pentru ea.
  Future<void> scheduleComponentReminder(
    ComponentDefinition definition,
    ComponentRecord record,
    String vehicleLabel,
  ) async {
    await cancelForComponent(record.vehicleId, record.componentId);
    final intervalMonths = record.customIntervalMonths ?? definition.intervalMonths;
    if (intervalMonths == null || record.lastChangedDate == null) return;

    final key = '${record.vehicleId}|${record.componentId}';
    final dueSoonMonths = (intervalMonths * 0.85).round();
    await _scheduleAt(
      _idFor(key, 0),
      S.componentDueSoonTitle(definition.name),
      S.componentDueSoonBody(definition.name, vehicleLabel),
      _atNine(_addMonths(record.lastChangedDate!, dueSoonMonths)),
    );
    await _scheduleAt(
      _idFor(key, 1),
      S.componentOverdueTitle(definition.name),
      S.componentOverdueBody(definition.name, vehicleLabel),
      _atNine(_addMonths(record.lastChangedDate!, intervalMonths)),
    );
  }

  Future<void> cancelForComponent(String vehicleId, String componentId) async {
    final key = '$vehicleId|$componentId';
    await _cancel(_idFor(key, 0));
    await _cancel(_idFor(key, 1));
  }

  /// Șterge starea de deduplicare din `checkComponentStatuses` pentru o
  /// componentă — de apelat înainte de acea verificare ori de câte ori
  /// utilizatorul chiar a introdus date noi pentru componenta respectivă
  /// (editare directă, bifă la revizie, profil de mentenanță aplicat).
  /// Altfel, dacă noul status recalculat e IDENTIC cu ultimul notificat (ex.
  /// tot "Recomandat curând", doar la un alt kilometraj), verificarea l-ar
  /// considera "deja notificat" și ar sări peste — corect pentru salvări
  /// repetate ale aceluiași kilometraj pe mașină, dar greșit când utilizatorul
  /// chiar a înregistrat o schimbare reală și se așteaptă la un răspuns
  /// imediat despre noul status.
  Future<void> resetComponentNotificationState(String vehicleId, String componentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('component_notified_${vehicleId}_$componentId');
  }

  /// Verifică ACUM statusul tuturor componentelor mașinii (esențiale + extra
  /// legate) față de kilometrajul curent și trimite o notificare imediată
  /// (nu programată) pentru fiecare care tocmai a intrat în "Recomandat
  /// curând"/"Depășit" — asta acoperă partea în km a intervalului, care nu
  /// poate fi programată dinainte. Ține minte în `SharedPreferences` ultimul
  /// status notificat per componentă, ca să nu retrimită aceeași notificare
  /// la fiecare salvare de kilometraj cât timp starea nu se schimbă. Apelată
  /// după ce utilizatorul actualizează kilometrajul curent al mașinii.
  Future<void> checkComponentStatuses(
    Vehicle vehicle,
    List<ComponentRecord> records,
    Set<String> extraComponentIds,
  ) async {
    final recordsByComponent = {for (final r in records) r.componentId: r};
    final components = [
      ...essentialComponents,
      ...extraComponentCatalog.where((d) => extraComponentIds.contains(d.id)),
    ];
    final prefs = await SharedPreferences.getInstance();

    for (final definition in components) {
      final record = recordsByComponent[definition.id];
      final status = computeComponentStatus(
        definition: definition,
        record: record,
        currentMileage: vehicle.mileage,
      );
      final prefKey = 'component_notified_${vehicle.id}_${definition.id}';
      final lastNotified = prefs.getString(prefKey);

      if (status == ComponentStatus.dueSoon || status == ComponentStatus.overdue) {
        final statusKey = status.name;
        if (lastNotified == statusKey) continue;
        final shown = await _showNow(
          _idFor('$prefKey|now', 0),
          status == ComponentStatus.overdue
              ? S.componentOverdueTitle(definition.name)
              : S.componentDueSoonTitle(definition.name),
          status == ComponentStatus.overdue
              ? S.componentOverdueBody(definition.name, vehicle.name)
              : S.componentDueSoonBody(definition.name, vehicle.name),
        );
        // Marcăm ca notificat DOAR dacă `_plugin.show` chiar a reușit — altfel
        // un eșec silențios (permisiune neacordată, cache de notificări
        // corupt) ar bloca PERMANENT orice notificare viitoare pentru acest
        // status, fiindcă `lastNotified == statusKey` ar rămâne adevărat la
        // infinit cât timp componenta nu iese din dueSoon/overdue.
        if (shown) await prefs.setString(prefKey, statusKey);
      } else if (lastNotified != null) {
        await prefs.remove(prefKey);
      }
    }
  }

  /// Întoarce `true` doar dacă `_plugin.show` chiar a reușit — apelantul
  /// (`checkComponentStatuses`) folosește asta ca să NU marcheze o
  /// componentă ca "notificată" când afișarea a eșuat silențios.
  Future<bool> _showNow(int id, String title, String body) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
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
      );
      return true;
    } catch (_) {
      // Idem restul serviciului: nu blocăm fluxul utilizatorului dacă
      // plugin-ul de notificări eșuează.
      return false;
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day, date.hour, date.minute);
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
