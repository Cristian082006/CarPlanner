import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'costs_calendar_screen.dart';
import 'garage_screen.dart';
import 'home_screen.dart';
import 'house_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _garageKey = GlobalKey<GarageScreenState>();
  final _houseKey = GlobalKey<HouseScreenState>();
  final _costsKey = GlobalKey<CostsCalendarScreenState>();

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
    _refreshTab(index);
  }

  late final _tabs = [
    HomeScreen(key: _homeKey, onSeeAllInTab: _goToTab),
    GarageScreen(key: _garageKey),
    HouseScreen(key: _houseKey),
    CostsCalendarScreen(key: _costsKey),
    const SettingsScreen(),
  ];

  /// Fiecare tab își încarcă datele o singură dată, în `initState` — cum
  /// `IndexedStack` păstrează toate tab-urile montate simultan (nu le
  /// recreează la schimbare), o modificare făcută într-un tab (ex. adaugă
  /// un document în Garaj) nu s-ar reflecta altfel în alt tab (ex. lista de
  /// atenționări din Acasă) decât la un pull-to-refresh manual. Re-încărcăm
  /// explicit tab-ul nou selectat de fiecare dată când userul schimbă tabul.
  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refresh();
        break;
      case 1:
        _garageKey.currentState?.refresh();
        break;
      case 2:
        _houseKey.currentState?.refresh();
        break;
      case 3:
        _costsKey.currentState?.refresh();
        break;
    }
  }

  void _onDestinationSelected(int index) => _goToTab(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: S.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_car_outlined),
            selectedIcon: const Icon(Icons.directions_car),
            label: S.navGarage,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_work_outlined),
            selectedIcon: const Icon(Icons.home_work),
            label: S.navHouse,
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: S.navCosts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: S.navSettings,
          ),
        ],
      ),
    );
  }
}
