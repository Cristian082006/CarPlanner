import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../utils/alerts.dart';
import '../utils/date_utils.dart';
import '../widgets/document_tile.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_document_screen.dart';
import 'add_edit_vehicle_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'vehicle_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  List<Vehicle> _vehicles = [];
  List<CarDocument> _allDocuments = [];
  List<ServiceRecord> _allServiceRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles = await _db.getVehicles();
    final documents = await _db.getAllDocuments();
    final records = await _db.getAllServiceRecords();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _allDocuments = documents;
      _allServiceRecords = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vehiclesById = {for (final v in _vehicles) v.id: v};
    final alerts = buildAlerts(
      documents: _allDocuments,
      serviceRecords: _allServiceRecords,
      vehiclesById: vehiclesById,
    ).where((a) => a.daysUntil <= 30).take(5).toList();

    final standaloneDocs = _allDocuments.where((d) => d.vehicleId == null).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: S.remindersTooltip,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: S.settingsTitle,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            if (alerts.isNotEmpty) ...[
              _SectionHeader(S.alertsHeader),
              ...alerts.map((a) => ListTile(
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
                  )),
            ],
            _SectionHeader(S.myCarsHeader),
            if (_vehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  S.noCarsYet,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._vehicles.map((v) {
                final vehicleAlerts = alerts.where((a) => a.vehicleId == v.id).toList();
                final nearest = vehicleAlerts.isEmpty ? null : vehicleAlerts.first;
                final vehicleDocs = _allDocuments.where((d) => d.vehicleId == v.id).toList()
                  ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VehicleCard(
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
                    ),
                    ...vehicleDocs.map((d) => Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: DocumentTile(
                            document: d,
                            vehicleLabel: v.name,
                            plateNumber: v.plateNumber,
                            vin: v.vin,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditDocumentScreen(vehicleId: v.id, document: d),
                                ),
                              );
                              _load();
                            },
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditDocumentScreen(vehicleId: v.id),
                              ),
                            );
                            _load();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(S.addVehicleDocumentsShortcut),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            _SectionHeader(S.houseHeader),
            ...standaloneDocs.map((d) => DocumentTile(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditDocumentScreen(vehicleId: null),
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.add),
                label: Text(S.addHomeInsurance),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditVehicleScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: Text(S.car),
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
