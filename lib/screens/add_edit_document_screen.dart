import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/vehicle.dart';
import '../services/document_scanner_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/document_verification_utils.dart';
import '../widgets/photo_picker_field.dart';

class AddEditDocumentScreen extends StatefulWidget {
  /// Null pentru documente fără mașină asociată (ex: asigurare locuință).
  final String? vehicleId;
  final CarDocument? document;

  const AddEditDocumentScreen({super.key, required this.vehicleId, this.document});

  @override
  State<AddEditDocumentScreen> createState() => _AddEditDocumentScreenState();
}

class _AddEditDocumentScreenState extends State<AddEditDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _providerCtrl;
  late final TextEditingController _policyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _notesCtrl;
  late DocumentType _type;
  DateTime? _startDate;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  String? _photoPath;
  bool _saving = false;
  bool _expiryDateTouched = false;
  Vehicle? _vehicle;

  bool get _isEditing => widget.document != null;
  bool get _isForVehicle => widget.vehicleId != null;
  bool get _isPolicyType => _type == DocumentType.rca || _type == DocumentType.casco;

  List<DocumentType> get _availableTypes => _isForVehicle
      ? [DocumentType.rca, DocumentType.casco, DocumentType.rovinieta, DocumentType.itp, DocumentType.other]
      : [DocumentType.homeInsurance, DocumentType.other];

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _type = d?.type ?? _availableTypes.first;
    _titleCtrl = TextEditingController(text: d?.title ?? '');
    _providerCtrl = TextEditingController(text: d?.provider ?? '');
    _policyCtrl = TextEditingController(text: d?.policyNumber ?? '');
    _costCtrl = TextEditingController(text: d?.cost?.toString() ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _startDate = d?.startDate;
    _expiryDate = d?.expiryDate ?? _expiryDate;
    _expiryDateTouched = d != null;
    _photoPath = d?.photoPath;
    if (widget.vehicleId != null) _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    final vehicle = await _db.getVehicle(widget.vehicleId!);
    if (!mounted) return;
    setState(() => _vehicle = vehicle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _providerCtrl.dispose();
    _policyCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : _expiryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _expiryDate = picked;
        _expiryDateTouched = true;
      }
    });
  }

  Future<void> _tryAutoFillFromPdf(String path) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.extractingPdfData), duration: const Duration(seconds: 2)),
    );

    final data = await DocumentScannerService.instance.scanRcaPdf(path);
    if (!mounted || data == null) return;

    if (_providerCtrl.text.trim().isEmpty && data.provider != null) {
      _providerCtrl.text = data.provider!;
    }
    if (_policyCtrl.text.trim().isEmpty && data.policyNumber != null) {
      _policyCtrl.text = data.policyNumber!;
    }
    setState(() {
      if (_startDate == null && data.startDate != null) _startDate = data.startDate;
      if (!_expiryDateTouched && data.expiryDate != null) {
        _expiryDate = data.expiryDate!;
        _expiryDateTouched = true;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data.fieldsFound > 0 ? S.pdfDataFilled(data.fieldsFound) : S.pdfDataNotFound),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final document = CarDocument(
      id: widget.document?.id ?? const Uuid().v4(),
      vehicleId: widget.vehicleId,
      type: _type,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      provider: _providerCtrl.text.trim().isEmpty ? null : _providerCtrl.text.trim(),
      policyNumber: _policyCtrl.text.trim().isEmpty ? null : _policyCtrl.text.trim(),
      startDate: _startDate,
      expiryDate: _expiryDate,
      cost: double.tryParse(_costCtrl.text.trim().replaceAll(',', '.')),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      photoPath: _photoPath,
    );

    if (_isEditing) {
      await _db.updateDocument(document);
    } else {
      await _db.insertDocument(document);
    }

    String vehicleLabel = S.homeLabel;
    if (widget.vehicleId != null) {
      final vehicle = await _db.getVehicle(widget.vehicleId!);
      vehicleLabel = vehicle?.name ?? S.yourCar;
    }
    await NotificationService.instance.scheduleDocumentReminders(document, vehicleLabel);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteDocumentTitle),
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
    await NotificationService.instance.cancelForDocument(widget.document!.id);
    await _db.deleteDocument(widget.document!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? S.editDocument : S.newDocument),
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
            DropdownButtonFormField<DocumentType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: S.documentType),
              items: _availableTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: S.customNameOptional),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _providerCtrl,
                    decoration: InputDecoration(labelText: S.provider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _policyCtrl,
                    decoration: InputDecoration(labelText: S.policyNumber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.startDateOptional),
              subtitle: Text(formatDate(_startDate)),
              trailing: _startDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _startDate = null),
                    )
                  : const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(S.expiryDate),
              subtitle: Text(formatDate(_expiryDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(isStart: false),
            ),
            if (hasOfficialVerification(_type))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => verifyDocumentOnOfficialSite(
                    context,
                    type: _type,
                    plateNumber: _vehicle?.plateNumber,
                    vin: _vehicle?.vin,
                  ),
                  icon: const Icon(Icons.travel_explore_outlined, size: 18),
                  label: Text(S.verifyOnOfficialSite),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costCtrl,
              decoration: InputDecoration(labelText: S.costOptional),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: S.notes, alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            PhotoPickerField(
              initialPath: _photoPath,
              label: _isPolicyType ? S.documentPhotoOrPdf : S.documentPhoto,
              allowPdf: true,
              onChanged: (path) {
                _photoPath = path;
                if (path != null && path.toLowerCase().endsWith('.pdf') && _isPolicyType) {
                  _tryAutoFillFromPdf(path);
                }
              },
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
