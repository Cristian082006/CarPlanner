import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/component_record.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../utils/vehicle_components.dart';
import '../widgets/photo_picker_field.dart';

class AddEditServiceRecordScreen extends StatefulWidget {
  final Vehicle vehicle;
  final ServiceRecord? record;

  const AddEditServiceRecordScreen({super.key, required this.vehicle, this.record});

  @override
  State<AddEditServiceRecordScreen> createState() => _AddEditServiceRecordScreenState();
}

class _AddEditServiceRecordScreenState extends State<AddEditServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _workshopCtrl;
  late final TextEditingController _nextMileageCtrl;
  DateTime _date = DateTime.now();
  DateTime? _nextServiceDate;
  String? _photoPath;
  bool _saving = false;
  final Set<String> _changedComponentIds = {};
  Map<String, ComponentRecord> _existingComponentRecords = {};

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _mileageCtrl = TextEditingController(text: r?.mileage?.toString() ?? '');
    _descriptionCtrl = TextEditingController(text: r?.description ?? '');
    _costCtrl = TextEditingController(text: r?.cost?.toString() ?? '');
    _workshopCtrl = TextEditingController(text: r?.workshop ?? '');
    _nextMileageCtrl = TextEditingController(text: r?.nextServiceMileage?.toString() ?? '');
    _date = r?.date ?? DateTime.now();
    _nextServiceDate = r?.nextServiceDate;
    _photoPath = r?.photoPath;
    _changedComponentIds.addAll(r?.changedComponentIds ?? const []);
    _loadExistingComponentRecords();
  }

  Future<void> _loadExistingComponentRecords() async {
    final records = await _db.getComponentRecords(widget.vehicle.id);
    if (!mounted) return;
    setState(() {
      _existingComponentRecords = {for (final rec in records) rec.componentId: rec};
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _mileageCtrl.dispose();
    _descriptionCtrl.dispose();
    _costCtrl.dispose();
    _workshopCtrl.dispose();
    _nextMileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNextService}) async {
    final initial = isNextService ? (_nextServiceDate ?? DateTime.now()) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isNextService) {
        _nextServiceDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final mileage = int.tryParse(_mileageCtrl.text.trim());
    final record = ServiceRecord(
      id: widget.record?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicle.id,
      date: _date,
      mileage: mileage,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim().replaceAll(',', '.')),
      workshop: _workshopCtrl.text.trim().isEmpty ? null : _workshopCtrl.text.trim(),
      nextServiceDate: _nextServiceDate,
      nextServiceMileage: int.tryParse(_nextMileageCtrl.text.trim()),
      photoPath: _photoPath,
      changedComponentIds: _changedComponentIds.toList(),
    );

    if (_isEditing) {
      await _db.updateServiceRecord(record);
    } else {
      await _db.insertServiceRecord(record);
    }
    await NotificationService.instance.scheduleServiceReminder(record, widget.vehicle.name);
    await _syncChangedComponents(mileage);

    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Actualizează data (și kilometrajul) ultimei schimbări în pagina de
  /// componente pentru fiecare componentă bifată mai sus, folosind data
  /// reviziei curente — păstrează notițele existente ale componentei.
  Future<void> _syncChangedComponents(int? mileage) async {
    for (final componentId in _changedComponentIds) {
      final existing = _existingComponentRecords[componentId];
      final record = ComponentRecord(
        vehicleId: widget.vehicle.id,
        componentId: componentId,
        lastChangedDate: _date,
        lastChangedMileage: mileage ?? existing?.lastChangedMileage,
        notes: existing?.notes,
        customIntervalKm: existing?.customIntervalKm,
        customIntervalMonths: existing?.customIntervalMonths,
        customIntervalSource: existing?.customIntervalSource,
      );
      await _db.upsertComponentRecord(record);
      final definition = findComponentDefinition(componentId);
      if (definition != null) {
        await NotificationService.instance.scheduleComponentReminder(
          definition,
          record,
          widget.vehicle.name,
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteServiceRecordTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationService.instance.cancelForServiceRecord(widget.record!.id);
    await _db.deleteServiceRecord(widget.record!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? S.editServiceRecord : S.newServiceRecord),
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
              decoration: InputDecoration(
                labelText: S.serviceTitleHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? S.requiredField : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.date),
              subtitle: Text(formatDate(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isNextService: false),
            ),
            TextFormField(
              controller: _mileageCtrl,
              decoration: InputDecoration(labelText: S.mileageAtServiceDate),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: S.whatChangedHint,
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text(S.changedComponentsHeader, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              S.changedComponentsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            ...essentialComponents.map(
              (definition) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(definition.name),
                value: _changedComponentIds.contains(definition.id),
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _changedComponentIds.add(definition.id);
                  } else {
                    _changedComponentIds.remove(definition.id);
                  }
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: InputDecoration(labelText: S.cost),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _workshopCtrl,
                    decoration: InputDecoration(labelText: S.workshop),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(S.nextServiceReminderHeader,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.nextServiceDate),
              subtitle: Text(formatDate(_nextServiceDate)),
              trailing: _nextServiceDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _nextServiceDate = null),
                    )
                  : const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isNextService: true),
            ),
            TextFormField(
              controller: _nextMileageCtrl,
              decoration: InputDecoration(labelText: S.nextServiceMileage),
              keyboardType: TextInputType.number,
            ),
            const Divider(height: 32),
            PhotoPickerField(
              initialPath: _photoPath,
              label: S.serviceBookPhoto,
              onChanged: (path) => _photoPath = path,
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
