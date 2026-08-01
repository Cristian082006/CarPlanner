import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/reminder.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';
import '../utils/alerts.dart';
import '../utils/date_utils.dart';
import '../widgets/document_tile.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_document_screen.dart';
import 'add_edit_reminder_screen.dart';
import 'vehicle_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Apelat când userul apasă „Vezi toate” dintr-o secțiune, ca să comute
  /// tabul activ din `MainShell` (Mașini = 1, Casă = 2). Null în teste/preview.
  final void Function(int tabIndex)? onSeeAllInTab;

  const HomeScreen({super.key, this.onSeeAllInTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _alertsPreviewCount = 4;

  final _db = DatabaseHelper.instance;

  List<AlertItem> _alerts = [];
  List<Vehicle> _vehicles = [];
  List<CarDocument> _houseDocuments = [];
  List<Reminder> _reminders = [];
  Map<String, Vehicle> _vehiclesById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _deleteReminder(Reminder reminder) async {
    await NotificationService.instance.cancelForReminder(reminder.id);
    await _db.deleteReminder(reminder.id);
    _load();
  }

  Future<void> _addOrEditReminder([Reminder? reminder]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditReminderScreen(reminder: reminder)),
    );
    _load();
  }

  Future<void> _load() async {
    final vehicles = await _db.getVehicles();
    final documents = await _db.getAllDocuments();
    final records = await _db.getAllServiceRecords();
    final reminders = await _db.getReminders();
    final vehiclesById = {for (final v in vehicles) v.id: v};
    if (!mounted) return;
    setState(() {
      _alerts = buildAlerts(
        documents: documents,
        serviceRecords: records,
        vehiclesById: vehiclesById,
      ).where((a) => a.daysUntil <= 30).toList();
      _vehicles = vehicles;
      _houseDocuments = documents.where((d) => d.vehicleId == null).toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      _reminders = reminders;
      _vehiclesById = vehiclesById;
      _loading = false;
    });
    // Re-programează reminder-ul lunar de kilometraj pentru toate mașinile —
    // idempotent și necesar ca migrare pentru mașinile adăugate înainte de
    // această funcționalitate (care altfel n-ar avea niciodată reminder-ul
    // programat, fiindcă el pornește doar la salvarea din formular).
    for (final vehicle in vehicles) {
      await NotificationService.instance.scheduleMileageReminder(vehicle);
    }
    // Reminder global de backup — vezi comentariul de la
    // `scheduleBackupReminder` (nu poate fi legat de momentul ștergerii
    // efective a aplicației, doar de un interval periodic). Anulat dacă nu
    // mai există nicio mașină, ca să nu deranjeze un utilizator care abia a
    // instalat aplicația și n-are încă date de pierdut.
    if (vehicles.isNotEmpty) {
      await NotificationService.instance.scheduleBackupReminder();
    } else {
      await NotificationService.instance.cancelBackupReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final alertsPreview = _alerts.take(_alertsPreviewCount).toList();

    return Scaffold(
      appBar: AppBar(title: Text(S.appName)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _SectionHeader(
              S.alertsHeader,
              onSeeAll: _alerts.length > _alertsPreviewCount ? () => widget.onSeeAllInTab?.call(3) : null,
            ),
            if (alertsPreview.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(S.allUpToDate, style: const TextStyle(color: Colors.grey)),
              )
            else
              // Aspect 3D cerut explicit de utilizator — la fel ca
              // `VehicleCard`/`DocumentTile`, în loc de `ListTile` plat.
              ...alertsPreview.map((a) => Card(
                    child: ListTile(
                      leading: Icon(a.icon, color: a.color),
                      title: Text(a.title),
                      subtitle: Text('${a.subtitle} • ${daysUntilLabel(a.daysUntil)}'),
                      onTap: () async {
                        if (a.vehicleId != null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailScreen(vehicleId: a.vehicleId!),
                            ),
                          );
                          _load();
                        }
                      },
                    ),
                  )),
            _SectionHeader(S.myCarsHeader, onSeeAll: () => widget.onSeeAllInTab?.call(1)),
            if (_vehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(S.noCarsYet, style: const TextStyle(color: Colors.grey)),
              )
            else
              ..._vehicles.map((v) {
                final vehicleAlerts = _alerts.where((a) => a.vehicleId == v.id).toList();
                final nearest = vehicleAlerts.isEmpty ? null : vehicleAlerts.first;
                return VehicleCard(
                  vehicle: v,
                  alertText: nearest != null ? daysUntilLabel(nearest.daysUntil) : null,
                  alertColor: nearest?.color,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicleId: v.id)),
                    );
                    _load();
                  },
                );
              }),
            _SectionHeader(S.houseWarningsHeader, onSeeAll: () => widget.onSeeAllInTab?.call(2)),
            if (_houseDocuments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(S.noHouseWarnings, style: const TextStyle(color: Colors.grey)),
              )
            else
              ..._houseDocuments.map((d) => DocumentTile(
                    document: d,
                    vehicleLabel: S.homeLabel,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditDocumentScreen(vehicleId: null, document: d),
                        ),
                      );
                      _load();
                    },
                  )),
            _SectionHeader(
              S.personalReminders,
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: S.addReminderTooltip,
                onPressed: () => _addOrEditReminder(),
              ),
            ),
            if (_reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(S.noPersonalReminders, style: const TextStyle(color: Colors.grey)),
              )
            else
              ..._reminders.map((r) => Dismissible(
                    key: ValueKey(r.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteReminder(r),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.alarm_outlined)),
                        title: Text(r.title),
                        subtitle: Text(
                          [
                            formatDate(r.date),
                            if (r.vehicleId != null) _vehiclesById[r.vehicleId]?.name,
                          ].whereType<String>().join(' • '),
                        ),
                        onTap: () => _addOrEditReminder(r),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const _SectionHeader(this.title, {this.onSeeAll, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (trailing != null) trailing!,
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(S.seeAll),
            ),
        ],
      ),
    );
  }
}
