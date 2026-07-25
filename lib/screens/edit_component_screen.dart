import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/component_record.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../utils/vehicle_components.dart';

class EditComponentScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleLabel;
  final ComponentDefinition definition;
  final ComponentRecord? record;

  const EditComponentScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.definition,
    this.record,
  });

  @override
  State<EditComponentScreen> createState() => _EditComponentScreenState();
}

class _EditComponentScreenState extends State<EditComponentScreen> {
  final _db = DatabaseHelper.instance;
  late final TextEditingController _mileageCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _lastChangedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mileageCtrl = TextEditingController(text: widget.record?.lastChangedMileage?.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.record?.notes ?? '');
    _lastChangedDate = widget.record?.lastChangedDate;
  }

  @override
  void dispose() {
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastChangedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _lastChangedDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final record = ComponentRecord(
      vehicleId: widget.vehicleId,
      componentId: widget.definition.id,
      lastChangedDate: _lastChangedDate,
      lastChangedMileage: int.tryParse(_mileageCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await _db.upsertComponentRecord(record);
    await NotificationService.instance.scheduleComponentReminder(
      widget.definition,
      record,
      widget.vehicleLabel,
    );
    // Un `lastChangedMileage` nou schimbă imediat raportul km-parcurși/interval
    // (spre deosebire de partea în luni, reprogramată mai sus) — verificăm
    // acum, la fel ca la salvarea kilometrajului mașinii din
    // `add_edit_vehicle_screen.dart`, altfel componenta poate intra direct în
    // dueSoon/overdue fără nicio notificare.
    final vehicle = await _db.getVehicle(widget.vehicleId);
    if (vehicle != null) {
      final records = await _db.getComponentRecords(widget.vehicleId);
      final extraIds = await _db.getExtraComponentIds(widget.vehicleId);
      // O editare directă e o introducere de date deliberată — resetăm
      // deduplicarea ca utilizatorul să primească mereu un răspuns imediat
      // despre noul status, chiar dacă e identic cu ultimul notificat.
      await NotificationService.instance
          .resetComponentNotificationState(widget.vehicleId, widget.definition.id);
      await NotificationService.instance.checkComponentStatuses(vehicle, records, extraIds);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.definition.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            S.recommendedInterval(widget.definition.effectiveIntervalLabel(widget.record)) +
                (widget.record?.customIntervalSource != null
                    ? S.customIntervalSuffix(widget.record!.customIntervalSource!)
                    : ''),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(S.lastChangedDate),
            subtitle: Text(formatDate(_lastChangedDate)),
            trailing: _lastChangedDate != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _lastChangedDate = null),
                  )
                : const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          TextFormField(
            controller: _mileageCtrl,
            decoration: InputDecoration(labelText: S.mileageAtLastChange),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            decoration: InputDecoration(labelText: S.notesOptional),
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
    );
  }
}
