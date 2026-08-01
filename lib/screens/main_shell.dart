import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav_bar.dart';
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
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          AppNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: S.navHome,
            color: kAccentColor,
          ),
          AppNavDestination(
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car,
            label: S.navGarage,
            color: kNavGarageColor,
          ),
          AppNavDestination(
            icon: Icons.home_work_outlined,
            selectedIcon: Icons.home_work,
            label: S.navHouse,
            color: kNavHouseColor,
          ),
          AppNavDestination(
            icon: Icons.payments_outlined,
            selectedIcon: Icons.payments,
            label: S.navCosts,
            color: kNavCostsColor,
          ),
          AppNavDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: S.navSettings,
            color: kNavSettingsColor,
          ),
        ],
      ),
    );
  }
}
