import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../widgets/document_tile.dart';
import 'add_edit_document_screen.dart';

class HouseScreen extends StatefulWidget {
  const HouseScreen({super.key});

  @override
  State<HouseScreen> createState() => HouseScreenState();
}

class HouseScreenState extends State<HouseScreen> {
  final _db = DatabaseHelper.instance;

  List<CarDocument> _standaloneDocs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final documents = await _db.getAllDocuments();
    if (!mounted) return;
    setState(() {
      _standaloneDocs = documents.where((d) => d.vehicleId == null).toList()
        ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.houseHeader)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 96),
          children: [
            ..._standaloneDocs.map((d) => DocumentTile(
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
    );
  }
}
