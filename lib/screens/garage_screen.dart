import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../models/vehicle.dart';
import '../utils/alerts.dart';
import '../utils/date_utils.dart';
import '../widgets/document_tile.dart';
import '../widgets/vehicle_card.dart';
import 'add_edit_document_screen.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});

  @override
  State<GarageScreen> createState() => GarageScreenState();
}

class GarageScreenState extends State<GarageScreen> {
  final _db = DatabaseHelper.instance;

  List<Vehicle> _vehicles = [];
  List<CarDocument> _allDocuments = [];
  List<AlertItem> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final vehicles = await _db.getVehicles();
    final documents = await _db.getAllDocuments();
    final records = await _db.getAllServiceRecords();
    final vehiclesById = {for (final v in vehicles) v.id: v};
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _allDocuments = documents;
      _alerts = buildAlerts(
        documents: documents,
        serviceRecords: records,
        vehiclesById: vehiclesById,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.myCarsHeader)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 96),
          children: [
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
                final vehicleAlerts = _alerts.where((a) => a.vehicleId == v.id).toList();
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'garageFab',
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
