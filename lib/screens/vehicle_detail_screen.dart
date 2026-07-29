import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/component_record.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/engine_lookup.dart';
import '../utils/maintenance_profiles.dart';
import '../utils/vehicle_components.dart';
import '../utils/vin_decoder.dart';
import '../widgets/document_tile.dart';
import '../widgets/engine_candidates_dialog.dart';
import '../widgets/service_record_tile.dart';
import 'add_edit_document_screen.dart';
import 'add_edit_service_record_screen.dart';
import 'add_edit_vehicle_screen.dart';
import 'edit_component_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _db = DatabaseHelper.instance;

  Vehicle? _vehicle;
  List<ServiceRecord> _records = [];
  List<CarDocument> _documents = [];
  List<ComponentRecord> _componentRecords = [];
  Set<String> _extraComponentIds = {};
  bool _loading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicle = await _db.getVehicle(widget.vehicleId);
    final records = await _db.getServiceRecords(widget.vehicleId);
    final documents = await _db.getDocumentsForVehicle(widget.vehicleId);
    final componentRecords = await _db.getComponentRecords(widget.vehicleId);
    final extraComponentIds = await _db.getExtraComponentIds(widget.vehicleId);
    if (!mounted) return;
    setState(() {
      _vehicle = vehicle;
      _records = records;
      _documents = documents;
      _componentRecords = componentRecords;
      _extraComponentIds = extraComponentIds;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vehicle = _vehicle;
    if (vehicle == null) {
      return Scaffold(body: Center(child: Text(S.carNotFound)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditVehicleScreen(vehicle: vehicle)),
              );
              _load();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _InfoTab(vehicle: vehicle, onChanged: _load),
          _RecordsTab(vehicle: vehicle, records: _records, onChanged: _load),
          _DocumentsTab(vehicle: vehicle, documents: _documents, onChanged: _load),
          _ComponentsTab(
            vehicle: vehicle,
            componentRecords: _componentRecords,
            extraComponentIds: _extraComponentIds,
            onChanged: _load,
          ),
        ],
      ),
      // Aceeași componentă NavigationBar (Material 3, pill de selecție) ca pe
      // ecranul Acasă (`main_shell.dart`) — cerut explicit de utilizator, ca
      // taburile mașinii să arate la fel ca navigarea principală.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (i) => setState(() => _currentTabIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: S.tabInfo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.build_outlined),
            selectedIcon: const Icon(Icons.build),
            label: S.tabService,
          ),
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: S.tabDocuments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: S.tabComponents,
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onChanged;
  const _InfoTab({required this.vehicle, required this.onChanged});

  /// Componenta (componentele) din tabul Componente pe care se aplică un
  /// rând `componenta` din view-ul `mentenanta_completa` — potrivire EXACTĂ
  /// pe numele din `vehicle_reference_data.dart` (nu pe prefix, fiindcă acum
  /// numele sunt fixe, nu variază per marcă). Câteva componente din setul de
  /// date (ulei diferențial, DPF, AdBlue) nu au încă un id în tracker —
  /// întorc listă goală și rândul e pur și simplu ignorat.
  static List<String> _componentIdsForName(String componentName) {
    switch (componentName) {
      case 'Ulei motor + filtru ulei':
        return const ['engine_oil', 'oil_filter'];
      case 'Filtru aer motor':
        return const ['air_filter'];
      case 'Filtru habitaclu (polen)':
        return const ['cabin_filter'];
      case 'Filtru combustibil':
        return const ['fuel_filter'];
      case 'Curea/lant de distributie':
      case 'Rola intinzatoare + pompa apa (kit distributie)':
        return const ['timing_belt'];
      case 'Curea accesorii (alternator/servo/AC)':
        return const ['accessory_belt'];
      case 'Lichid de racire (antigel)':
        return const ['coolant'];
      case 'Lichid de frana (DOT)':
        return const ['brake_fluid'];
      case 'Placute de frana fata':
        return const ['brake_pads_front'];
      case 'Placute de frana spate':
        return const ['brake_pads_rear'];
      case 'Discuri de frana fata':
      case 'Discuri de frana spate':
        return const ['brake_discs'];
      case 'Bujii (benzina)':
        return const ['spark_plugs'];
      case 'Bujii incandescente (diesel)':
        return const ['glow_plugs'];
      case 'Ulei cutie automata (ATF) + filtru':
      case 'Ulei cutie manuala':
        return const ['transmission_fluid'];
      case 'Baterie 12V':
        return const ['battery'];
      default:
        return const [];
    }
  }

  static String _engineDisplayName(Map<String, Object?> engine) {
    final parts = [engine['marca_nume'], engine['model_nume'], engine['model_generatie']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
    final comercial = engine['denumire_comerciala'] as String?;
    final label = comercial?.isNotEmpty == true ? '$parts — $comercial' : parts;
    return '$label (${engine['cod_motor']})';
  }

  Future<void> _applyMaintenanceProfile(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final label = '${vehicle.make} ${vehicle.model}'.trim();

    var engineCode = vehicle.engineCode;
    // Fără cod motor completat manual, dar cu VIN disponibil — încearcă să-l
    // deducă acum, la fel ca butonul de decodare VIN din ecranul de
    // adăugare/editare, în loc să sară direct la profilul generic pe
    // marcă/model/an. Utilizatorul tot alege motorul exact din listă (sau
    // anulează), nu se completează nimic fără confirmare.
    if ((engineCode == null || engineCode.trim().isEmpty) &&
        vehicle.vin != null &&
        isValidVinFormat(vehicle.vin!)) {
      final vinResult = await resolveEngineCandidatesFromVin(
        db,
        vin: vehicle.vin!,
        make: vehicle.make,
        model: vehicle.model,
      );
      if (vinResult.candidates.isNotEmpty) {
        if (!context.mounted) return;
        final chosen = await showEngineCandidatesDialog(context, vinResult);
        if (chosen != null) {
          engineCode = chosen['cod_motor'] as String;
          await db.updateVehicle(vehicle.copyWith(engineCode: engineCode));
        }
      }
    }

    final engine = await db.getEngineForCode(engineCode, make: vehicle.make, model: vehicle.model);
    final engineRows = engine != null
        ? await db.getMaintenanceIntervalsForMotorId(engine['id'] as int)
        : <Map<String, Object?>>[];
    final engineDisplayName = engine != null ? _engineDisplayName(engine) : null;

    final fallbackProfile = engineRows.isEmpty
        ? resolveMaintenanceProfile(make: vehicle.make, model: vehicle.model, year: vehicle.year)
        : null;

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.applyMaintenanceProfileTitle(label)),
        content: Text(
          engineRows.isNotEmpty
              ? S.applyMaintenanceProfileBodyEngine(
                  engineDisplayName!,
                  engineRows.map((r) => r['componenta'] as String).toSet().join(', '),
                )
              : fallbackProfile != null
                  ? S.applyMaintenanceProfileBody(fallbackProfile.displayName)
                  : S.applyMaintenanceProfileBodyUnknown(label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.apply)),
        ],
      ),
    );
    if (confirmed != true) return;

    final existingRecords = await db.getComponentRecords(vehicle.id);
    final recordsById = {for (final r in existingRecords) r.componentId: r};
    final existingExtras = await db.getExtraComponentIds(vehicle.id);
    var updatedCount = 0;
    var addedCount = 0;

    if (engineRows.isNotEmpty) {
      for (final row in engineRows) {
        for (final componentId in _componentIdsForName(row['componenta'] as String)) {
          if (!essentialComponents.any((d) => d.id == componentId) &&
              !existingExtras.contains(componentId)) {
            await db.addExtraComponent(vehicle.id, componentId);
            existingExtras.add(componentId);
            addedCount++;
          }
          final existing = recordsById[componentId];
          final updatedRecord = ComponentRecord(
            vehicleId: vehicle.id,
            componentId: componentId,
            lastChangedDate: existing?.lastChangedDate,
            lastChangedMileage: existing?.lastChangedMileage,
            notes: existing?.notes,
            customIntervalKm: row['interval_km'] as int?,
            customIntervalMonths: row['interval_luni'] as int?,
            customIntervalSource: engineDisplayName,
          );
          await db.upsertComponentRecord(updatedRecord);
          // Aplicarea profilului e o introducere de date deliberată —
          // resetăm deduplicarea ca verificarea de mai jos să anunțe chiar
          // dacă noul status e identic cu ultimul notificat.
          await NotificationService.instance
              .resetComponentNotificationState(vehicle.id, componentId);
          final definition = findComponentDefinition(componentId);
          if (definition != null) {
            await NotificationService.instance
                .scheduleComponentReminder(definition, updatedRecord, vehicle.name);
          }
          updatedCount++;
        }
      }
    } else if (fallbackProfile != null) {
      for (final componentId in const ['engine_oil', 'oil_filter']) {
        final existing = recordsById[componentId];
        final updatedRecord = ComponentRecord(
          vehicleId: vehicle.id,
          componentId: componentId,
          lastChangedDate: existing?.lastChangedDate,
          lastChangedMileage: existing?.lastChangedMileage,
          notes: existing?.notes,
          customIntervalKm: fallbackProfile.engineOilIntervalKm,
          customIntervalMonths: fallbackProfile.engineOilIntervalMonths,
          customIntervalSource: fallbackProfile.displayName,
        );
        await db.upsertComponentRecord(updatedRecord);
        await NotificationService.instance
            .resetComponentNotificationState(vehicle.id, componentId);
        final definition = findComponentDefinition(componentId);
        if (definition != null) {
          await NotificationService.instance
              .scheduleComponentReminder(definition, updatedRecord, vehicle.name);
        }
        updatedCount++;
      }
    }

    for (final extraId in universalExtraComponentIds) {
      if (!existingExtras.contains(extraId)) {
        await db.addExtraComponent(vehicle.id, extraId);
        addedCount++;
      }
    }

    // Un interval custom nou (`customIntervalKm`/`customIntervalMonths`) poate
    // schimba imediat raportul km-parcurși/interval al unei componente chiar
    // fără nicio schimbare de `lastChangedMileage` — ex. de la 90.000 km
    // generic la 60.000 km specific motorului, cu o mașină deja la 55.000 km
    // de la ultima schimbare. La fel ca la editarea directă a unei
    // componente, verificăm acum dacă vreuna a intrat în dueSoon/overdue.
    final refreshedRecords = await db.getComponentRecords(vehicle.id);
    await NotificationService.instance
        .checkComponentStatuses(vehicle, refreshedRecords, existingExtras);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.maintenanceProfileApplied(updatedCount, addedCount))),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry(S.make, vehicle.make),
      MapEntry(S.model, vehicle.model),
      if (vehicle.year != null) MapEntry(S.year, vehicle.year.toString()),
      MapEntry(S.plateNumber, vehicle.plateNumber),
      if (vehicle.vin?.isNotEmpty == true) MapEntry(S.vin, vehicle.vin!),
      if (vehicle.fuelType?.isNotEmpty == true) MapEntry(S.fuelType, vehicle.fuelType!),
      if (vehicle.engineCode?.isNotEmpty == true) MapEntry(S.engineCode, vehicle.engineCode!),
      MapEntry(S.currentMileage, '${vehicle.mileage} km'),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 160, child: Text(r.key, style: const TextStyle(color: Colors.grey))),
                  Expanded(child: Text(r.value, style: const TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            )),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kAttentionColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _applyMaintenanceProfile(context),
          icon: const Icon(Icons.checklist_rtl_outlined),
          label: Text(S.suggestMaintenanceProfile('${vehicle.make} ${vehicle.model}'.trim())),
        ),
      ],
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final Vehicle vehicle;
  final List<ServiceRecord> records;
  final VoidCallback onChanged;

  const _RecordsTab({required this.vehicle, required this.records, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: records.isEmpty
          ? Center(child: Text(S.noServiceRecordsYet))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return ServiceRecordTile(
                  record: r,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditServiceRecordScreen(vehicle: vehicle, record: r),
                      ),
                    );
                    onChanged();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'serviceRecordFab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditServiceRecordScreen(vehicle: vehicle)),
          );
          onChanged();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DocumentsTab extends StatelessWidget {
  final Vehicle vehicle;
  final List<CarDocument> documents;
  final VoidCallback onChanged;

  const _DocumentsTab({required this.vehicle, required this.documents, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: documents.isEmpty
          ? Center(child: Text(S.noDocumentsYet))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final d = documents[index];
                return DocumentTile(
                  document: d,
                  vehicleLabel: vehicle.name,
                  plateNumber: vehicle.plateNumber,
                  vin: vehicle.vin,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditDocumentScreen(vehicleId: vehicle.id, document: d),
                      ),
                    );
                    onChanged();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'vehicleDocumentsFab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditDocumentScreen(vehicleId: vehicle.id)),
          );
          onChanged();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ComponentsTab extends StatelessWidget {
  final Vehicle vehicle;
  final List<ComponentRecord> componentRecords;
  final Set<String> extraComponentIds;
  final VoidCallback onChanged;

  const _ComponentsTab({
    required this.vehicle,
    required this.componentRecords,
    required this.extraComponentIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final recordsByComponent = {for (final r in componentRecords) r.componentId: r};
    final components = [
      ...essentialComponents,
      ...extraComponentCatalog.where((d) => extraComponentIds.contains(d.id)),
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final definition = components[index];
        final record = recordsByComponent[definition.id];
        final status = computeComponentStatus(
          definition: definition,
          record: record,
          currentMileage: vehicle.mileage,
        );

        final subtitleParts = <String>[
          '${S.intervalPrefix}${definition.effectiveIntervalLabel(record)}'
              '${record?.customIntervalSource != null ? S.customIntervalSuffix(record!.customIntervalSource!) : ''}',
          if (record?.lastChangedDate != null || record?.lastChangedMileage != null)
            '${S.lastChangedPrefix}${formatDate(record?.lastChangedDate)}'
                '${record?.lastChangedMileage != null ? ' · ${record!.lastChangedMileage} km' : ''}'
          else
            S.notSet,
        ];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: status.color.withValues(alpha: 0.15),
            child: Icon(Icons.build_outlined, color: status.color),
          ),
          title: Text(definition.name),
          subtitle: Text(subtitleParts.join('\n')),
          isThreeLine: true,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(color: status.color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditComponentScreen(
                  vehicleId: vehicle.id,
                  vehicleLabel: vehicle.name,
                  definition: definition,
                  record: record,
                ),
              ),
            );
            onChanged();
          },
        );
      },
    );
  }
}
