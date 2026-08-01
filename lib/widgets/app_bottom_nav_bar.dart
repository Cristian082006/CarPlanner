import 'package:flutter/material.dart';

/// O destinație din bara de navigare de jos. [color] e cerut explicit de
/// utilizator ("fă butoanele de jos... colorate") — fiecare tab primește
/// propria culoare din apelant, nu o singură culoare neutră (`onSurface`)
/// pentru toate, ca înainte.
class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
  });
}

/// Bară de navigare de jos proprie, NU `NavigationBar` din Material —
/// cerut explicit de utilizator: „la fel și taburile din jos" să arate 3D
/// și să se vadă vizibil că le apeși. `NavigationBar`-ul standard (folosit
/// înainte, în `main_shell.dart`/`vehicle_detail_screen.dart`) primise deja
/// elevație prin `navigationBarTheme`, dar testat pe device real umbra nu
/// se vedea vizibil, iar `NavigationDestination` nu are nicio stare de
/// apăsare separată (doar ripple-ul standard Material) — nu era suficient
/// de clar ca feedback vizual. În loc să depindem de comportamentul intern
/// (și posibil inconsistent între platforme) al widget-ului Material,
/// desenăm explicit umbra (`BoxShadow`, garantat vizibilă) și implementăm
/// noi efectul de apăsare (`AnimatedScale`, se micșorează vizibil la
/// `onTapDown` și revine la `onTapUp`/`onTapCancel`).
///
/// **Mărime dublă + colorat**, cerut explicit imediat după prima variantă
/// (implicit neutră/`onSurface`, înălțime 68) — vezi [_barHeight]/
/// [_iconSize] mai jos și [AppNavDestination.color].
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  // Dublate față de varianta inițială (68/24/12).
  static const double _barHeight = 136;
  static const double _iconSize = 48;
  static const double _labelFontSize = 15;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                    iconSize: _iconSize,
                    labelFontSize: _labelFontSize,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final double iconSize;
  final double labelFontSize;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.iconSize,
    required this.labelFontSize,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tabColor = widget.destination.color;
    // Neselectat: aceeași culoare a tabului, dar estompată — tot "colorat",
    // nu gri neutru, doar mai discret decât tabul activ.
    final color = widget.selected ? tabColor : tabColor.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        // Efectul de "apăsare" cerut explicit — se micșorează vizibil cât
        // ține degetul pe el, revine la mărimea normală la ridicare.
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: widget.selected ? tabColor.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                widget.selected ? widget.destination.selectedIcon : widget.destination.icon,
                color: color,
                size: widget.iconSize,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.destination.label,
              style: TextStyle(
                fontSize: widget.labelFontSize,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
