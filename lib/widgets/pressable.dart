import 'package:flutter/material.dart';

/// Înfășoară orice widget cu un efect vizual de "apăsare" (se micșorează
/// vizibil cât ține degetul pe el, revine la mărimea normală la ridicare) —
/// cerut explicit de utilizator, ca „același efect" ca la
/// `AppBottomNavBar`, aplicat și pe carduri/butoane/FAB.
///
/// Folosește `Listener` (evenimente brute de pointer), NU `GestureDetector`
/// — `Listener` nu participă la arena de gesturi, deci nu intră în conflict
/// cu `onTap`/`InkWell`-ul propriu al widget-ului înfășurat (buton, ListTile
/// etc.). Poate fi pus în jurul oricărui widget existent, fără să-i schimbe
/// deloc comportamentul de tap.
class Pressable extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.94,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
