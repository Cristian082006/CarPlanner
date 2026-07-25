import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/vehicle.dart';
import '../services/document_scanner_service.dart';
import '../services/notification_service.dart';
import '../utils/engine_lookup.dart';
import '../utils/vin_decoder.dart';
import '../widgets/engine_candidates_dialog.dart';
import '../widgets/photo_picker_field.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddEditVehicleScreen({super.key, this.vehicle});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _vinCtrl;
  late final TextEditingController _fuelCtrl;
  late final TextEditingController _engineCodeCtrl;
  late final TextEditingController _mileageCtrl;
  String? _photoPath;
  bool _saving = false;
  bool _scanning = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _makeCtrl = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(text: v?.year?.toString() ?? '');
    _plateCtrl = TextEditingController(text: v?.plateNumber ?? '');
    _vinCtrl = TextEditingController(text: v?.vin ?? '');
    _fuelCtrl = TextEditingController(text: v?.fuelType ?? '');
    _engineCodeCtrl = TextEditingController(text: v?.engineCode ?? '');
    _mileageCtrl = TextEditingController(text: v?.mileage.toString() ?? '');
    _photoPath = v?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _plateCtrl.dispose();
    _vinCtrl.dispose();
    _fuelCtrl.dispose();
    _engineCodeCtrl.dispose();
    _mileageCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanTalon() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(S.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(S.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 90);
    if (photo == null) return;

    setState(() => _scanning = true);
    try {
      final data = await DocumentScannerService.instance.scanTalon(photo.path);
      if (data.make != null) _makeCtrl.text = data.make!;
      if (data.model != null) _modelCtrl.text = data.model!;
      if (data.vin != null) _vinCtrl.text = data.vin!;
      if (data.plateNumber != null) _plateCtrl.text = data.plateNumber!;
      if (data.engineCode != null) _engineCodeCtrl.text = data.engineCode!;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          data.fieldsFound > 0 ? S.scanFilledFields(data.fieldsFound) : S.scanNoData,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.scanFailed),
      ));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _decodeVinEngine() async {
    final vin = _vinCtrl.text.trim();
    if (!isValidVinFormat(vin)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.vinInvalidFormat)));
      return;
    }
    final make = _makeCtrl.text.trim();
    if (make.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.vinMakeRequired)));
      return;
    }

    final model = _modelCtrl.text.trim();
    final result = await resolveEngineCandidatesFromVin(_db, vin: vin, make: make, model: model);

    if (!mounted) return;
    if (result.detectedMake != null && result.detectedMake!.toLowerCase() != make.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.vinMakeMismatch(result.detectedMake!, make)),
      ));
    }

    if (result.candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.vinNoEngineMatches)));
      return;
    }

    final chosen = await showEngineCandidatesDialog(context, result);
    if (chosen == null) return;
    setState(() {
      _engineCodeCtrl.text = chosen['cod_motor'] as String;
      if (_fuelCtrl.text.trim().isEmpty && chosen['combustibil'] != null) {
        _fuelCtrl.text = chosen['combustibil'] as String;
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.vinEngineApplied)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()),
      plateNumber: _plateCtrl.text.trim(),
      vin: _vinCtrl.text.trim().isEmpty ? null : _vinCtrl.text.trim(),
      fuelType: _fuelCtrl.text.trim().isEmpty ? null : _fuelCtrl.text.trim(),
      engineCode: _engineCodeCtrl.text.trim().isEmpty ? null : _engineCodeCtrl.text.trim(),
      mileage: int.tryParse(_mileageCtrl.text.trim()) ?? 0,
      photoPath: _photoPath,
      createdAt: widget.vehicle?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      await _db.updateVehicle(vehicle);
    } else {
      await _db.insertVehicle(vehicle);
    }

    // Partea în km a intervalului componentelor nu poate fi programată
    // dinainte (nu știm când va ajunge utilizatorul la kilometrajul
    // respectiv) — verificăm reactiv acum, la fiecare actualizare a
    // kilometrajului curent, dacă vreo componentă tocmai a devenit
    // "Recomandat curând"/"Depășit". Vezi `NotificationService.
    // checkComponentStatuses`.
    final records = await _db.getComponentRecords(vehicle.id);
    final extraIds = await _db.getExtraComponentIds(vehicle.id);
    await NotificationService.instance.checkComponentStatuses(vehicle, records, extraIds);
    await NotificationService.instance.scheduleMileageReminder(vehicle);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteCarTitle),
        content: Text(S.deleteCarBody),
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
    await _db.deleteVehicle(widget.vehicle!.id);
    await NotificationService.instance.cancelMileageReminder(widget.vehicle!.id);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? S.editCar : S.newCar),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _scanning ? null : _scanTalon,
              icon: _scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined),
              label: Text(_scanning ? S.readingRegistration : S.scanRegistration),
            ),
            const SizedBox(height: 16),
            PhotoPickerField(
              initialPath: _photoPath,
              label: S.carPhoto,
              onChanged: (path) => _photoPath = path,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: S.nameHint),
              validator: (v) => (v == null || v.trim().isEmpty) ? S.requiredField : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration: InputDecoration(labelText: S.make),
                    validator: (v) => (v == null || v.trim().isEmpty) ? S.required : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: InputDecoration(labelText: S.model),
                    validator: (v) => (v == null || v.trim().isEmpty) ? S.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearCtrl,
                    decoration: InputDecoration(labelText: S.year),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _plateCtrl,
                    decoration: InputDecoration(labelText: S.plateNumber),
                    validator: (v) => (v == null || v.trim().isEmpty) ? S.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vinCtrl,
              decoration: InputDecoration(
                labelText: S.vinOptional,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.settings_input_component_outlined),
                  tooltip: S.decodeEngineFromVin,
                  onPressed: _decodeVinEngine,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fuelCtrl,
                    decoration: InputDecoration(labelText: S.fuelTypeOptional),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _engineCodeCtrl,
                    decoration: InputDecoration(labelText: S.engineCodeOptional),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileageCtrl,
              decoration: InputDecoration(labelText: S.currentMileage),
              keyboardType: TextInputType.number,
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
