import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/reminder.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String? _vehicleId;
  List<Vehicle> _vehicles = [];
  bool _saving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _date = r?.date ?? _date;
    _vehicleId = r?.vehicleId;
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await _db.getVehicles();
    if (!mounted) return;
    setState(() => _vehicles = vehicles);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final reminder = Reminder(
      id: widget.reminder?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      date: _date,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      vehicleId: _vehicleId,
    );

    if (_isEditing) {
      await _db.updateReminder(reminder);
    } else {
      await _db.insertReminder(reminder);
    }
    await NotificationService.instance.scheduleCustomReminder(reminder);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    await NotificationService.instance.cancelForReminder(widget.reminder!.id);
    await _db.deleteReminder(widget.reminder!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? S.editReminder : S.newReminder),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: S.title),
              validator: (v) => (v == null || v.trim().isEmpty) ? S.requiredField : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.date),
              subtitle: Text(formatDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _vehicleId,
              decoration: InputDecoration(labelText: S.linkedCarOptional),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(S.none)),
                ..._vehicles.map((v) => DropdownMenuItem<String?>(value: v.id, child: Text(v.name))),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: S.notes, alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_saving ? S.saving : S.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
