import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../l10n/strings.dart';
import '../models/car_document.dart';
import '../theme/app_theme.dart';
import '../widgets/document_tile.dart';
import '../widgets/pressable.dart';
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
        child: _standaloneDocs.isEmpty
            // Înainte ecranul gol nu arăta absolut nimic în afară de FAB —
            // niciun mesaj, spre deosebire de toate celelalte ecrane goale
            // din aplicație (`noCarsYet`, `noHouseWarnings`...). Adăugat
            // acum ca parte din "mai user friendly" — textul lung, mutat de
            // pe eticheta FAB-ului (vezi mai jos), explică aici ce se poate
            // adăuga.
            ? ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 56,
                          color: kNavHouseColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.houseEmptyState,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
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
                ],
              ),
      ),
      // Mutat din lista scrollabilă (unde era un buton inline, la finalul
      // documentelor) ca FAB fix jos — cerut explicit de utilizator, la fel
      // ca restul butoanelor "+" din aplicație (garage/vehicle_detail).
      // "Mai user friendly", cerut explicit imediat după: eticheta lungă
      // ("Adaugă asigurare, impozit, verificări sau alt document") era greu
      // de citit înghesuită într-un FAB — scurtată la `addHomeDocumentShort`,
      // textul complet a devenit mesajul de ecran gol de mai sus. Culoare
      // distinctă (`kNavHouseColor`, verde — aceeași cu tabul Casă din bara
      // de jos), nu implicit `colorScheme.primary` ca restul FAB-urilor.
      floatingActionButton: Pressable(
        child: FloatingActionButton.extended(
          heroTag: 'houseFab',
          backgroundColor: kNavHouseColor,
          foregroundColor: Colors.white,
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
          label: Text(S.addHomeDocumentShort),
        ),
      ),
    );
  }
}
