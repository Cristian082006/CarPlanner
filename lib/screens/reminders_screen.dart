import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/reminder.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';
import '../utils/alerts.dart';
import '../utils/date_utils.dart';
import 'add_edit_reminder_screen.dart';
import 'vehicle_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _db = DatabaseHelper.instance;

  List<Reminder> _reminders = [];
  List<AlertItem> _autoAlerts = [];
  Map<String, Vehicle> _vehiclesById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles = await _db.getVehicles();
    final vehiclesById = {for (final v in vehicles) v.id: v};
    final documents = await _db.getAllDocuments();
    final records = await _db.getAllServiceRecords();
    final reminders = await _db.getReminders();

    if (!mounted) return;
    setState(() {
      _vehiclesById = vehiclesById;
      _reminders = reminders;
      _autoAlerts = buildAlerts(
        documents: documents,
        serviceRecords: records,
        vehiclesById: vehiclesById,
      );
      _loading = false;
    });
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await NotificationService.instance.cancelForReminder(reminder.id);
    await _db.deleteReminder(reminder.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          _SectionHeader(S.personalReminders),
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
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.alarm_outlined)),
                    title: Text(r.title),
                    subtitle: Text(
                      [formatDate(r.date), if (r.vehicleId != null) _vehiclesById[r.vehicleId]?.name]
                          .whereType<String>()
                          .join(' • '),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditReminderScreen(reminder: r)),
                      );
                      _load();
                    },
                  ),
                )),
          _SectionHeader(S.automaticAlerts),
          if (_autoAlerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(S.nothingToTrack, style: const TextStyle(color: Colors.grey)),
            )
          else
            ..._autoAlerts.map((a) => ListTile(
                  leading: Icon(a.icon, color: a.color),
                  title: Text(a.title),
                  subtitle: Text('${a.subtitle} • ${daysUntilLabel(a.daysUntil)}'),
                  onTap: a.vehicleId != null
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailScreen(vehicleId: a.vehicleId!),
                            ),
                          );
                          _load();
                        }
                      : null,
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditReminderScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: Text(S.reminder),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
