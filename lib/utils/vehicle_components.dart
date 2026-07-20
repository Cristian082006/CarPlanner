import 'package:flutter/material.dart';

import '../models/component_record.dart';
import '../services/region_service.dart';

/// Un component esențial al mașinii, cu intervalul recomandat de schimbare.
/// Intervalele sunt valori orientative generale de mentenanță auto — pot
/// diferi față de recomandările producătorului pentru un model anume.
class ComponentDefinition {
  final String id;
  final int? intervalKm;
  final int? intervalMonths;

  const ComponentDefinition({
    required this.id,
    this.intervalKm,
    this.intervalMonths,
  });

  static bool get _ro => RegionService.instance.language == AppLanguage.ro;

  String get name => _names[id]![_ro ? 0 : 1];

  String get intervalLabel => formatIntervalLabel(intervalKm, intervalMonths);

  /// Eticheta intervalului efectiv pentru acest component la [record] —
  /// folosește intervalul personalizat al mașinii (dacă a fost setat printr-un
  /// profil de mentenanță pe marcă) în loc de valoarea generică implicită.
  String effectiveIntervalLabel(ComponentRecord? record) {
    return formatIntervalLabel(
      record?.customIntervalKm ?? intervalKm,
      record?.customIntervalMonths ?? intervalMonths,
    );
  }

  static String formatIntervalLabel(int? km, int? months) {
    final parts = <String>[];
    if (km != null) parts.add('${_formatKm(km)} km');
    if (months != null) parts.add(_formatMonths(months));
    if (parts.isEmpty) return _ro ? 'Variabil' : 'Varies';
    return parts.join(_ro ? ' sau ' : ' or ');
  }

  static String _formatKm(int km) {
    final thousands = km / 1000;
    return thousands == thousands.roundToDouble()
        ? '${thousands.round()}.000'
        : km.toString();
  }

  static String _formatMonths(int months) {
    if (months % 12 == 0) {
      final years = months ~/ 12;
      if (_ro) return years == 1 ? '1 an' : '$years ani';
      return years == 1 ? '1 year' : '$years years';
    }
    if (_ro) return '$months luni';
    return months == 1 ? '1 month' : '$months months';
  }

  /// Denumiri [română, engleză] per id de componentă.
  static const Map<String, List<String>> _names = {
    'engine_oil': ['Ulei motor', 'Engine oil'],
    'oil_filter': ['Filtru ulei', 'Oil filter'],
    'air_filter': ['Filtru aer', 'Air filter'],
    'cabin_filter': ['Filtru polen (habitaclu)', 'Cabin (pollen) filter'],
    'fuel_filter': ['Filtru combustibil', 'Fuel filter'],
    'brake_pads_front': ['Plăcuțe frână față', 'Front brake pads'],
    'brake_pads_rear': ['Plăcuțe frână spate', 'Rear brake pads'],
    'brake_discs': ['Discuri frână', 'Brake discs'],
    'brake_fluid': ['Lichid de frână', 'Brake fluid'],
    'timing_belt': ['Curea de distribuție', 'Timing belt'],
    'accessory_belt': ['Curea accesorii (transmisie)', 'Accessory belt'],
    'spark_plugs': ['Bujii', 'Spark plugs'],
    'battery': ['Baterie', 'Battery'],
    'coolant': ['Antigel (lichid răcire)', 'Coolant'],
    'tires': ['Anvelope', 'Tires'],
    'transmission_fluid': ['Ulei cutie de viteze', 'Transmission fluid'],
    'wiper_blades': ['Ștergătoare parbriz', 'Wiper blades'],
  };
}

const List<ComponentDefinition> essentialComponents = [
  ComponentDefinition(id: 'engine_oil', intervalKm: 12000, intervalMonths: 12),
  ComponentDefinition(id: 'oil_filter', intervalKm: 12000, intervalMonths: 12),
  ComponentDefinition(id: 'air_filter', intervalKm: 20000, intervalMonths: 24),
  ComponentDefinition(id: 'cabin_filter', intervalKm: 15000, intervalMonths: 12),
  ComponentDefinition(id: 'fuel_filter', intervalKm: 40000, intervalMonths: 48),
  ComponentDefinition(id: 'brake_pads_front', intervalKm: 40000),
  ComponentDefinition(id: 'brake_pads_rear', intervalKm: 50000),
  ComponentDefinition(id: 'brake_discs', intervalKm: 80000),
  ComponentDefinition(id: 'brake_fluid', intervalMonths: 24),
  ComponentDefinition(id: 'timing_belt', intervalKm: 90000, intervalMonths: 60),
  ComponentDefinition(id: 'accessory_belt', intervalKm: 80000),
  ComponentDefinition(id: 'spark_plugs', intervalKm: 40000),
  ComponentDefinition(id: 'battery', intervalMonths: 48),
  ComponentDefinition(id: 'coolant', intervalMonths: 36),
  ComponentDefinition(id: 'tires', intervalKm: 45000, intervalMonths: 60),
];

/// Componente suplimentare, dincolo de cele de mai sus — nu apar implicit pe
/// nicio mașină, ci doar dacă sunt adăugate explicit (ex: printr-un profil
/// de mentenanță pe marcă, vezi `maintenance_profiles.dart`).
const List<ComponentDefinition> extraComponentCatalog = [
  ComponentDefinition(id: 'transmission_fluid', intervalKm: 60000, intervalMonths: 60),
  ComponentDefinition(id: 'wiper_blades', intervalMonths: 12),
];

/// Caută o definiție de componentă (esențială sau suplimentară) după id.
ComponentDefinition? findComponentDefinition(String id) {
  for (final d in essentialComponents) {
    if (d.id == id) return d;
  }
  for (final d in extraComponentCatalog) {
    if (d.id == id) return d;
  }
  return null;
}

enum ComponentStatus { unset, ok, dueSoon, overdue }

extension ComponentStatusX on ComponentStatus {
  bool get _ro => RegionService.instance.language == AppLanguage.ro;

  String get label {
    switch (this) {
      case ComponentStatus.unset:
        return _ro ? 'Nesetat' : 'Not set';
      case ComponentStatus.ok:
        return 'OK';
      case ComponentStatus.dueSoon:
        return _ro ? 'Recomandat curând' : 'Due soon';
      case ComponentStatus.overdue:
        return _ro ? 'Depășit' : 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case ComponentStatus.unset:
        return Colors.grey;
      case ComponentStatus.ok:
        return const Color(0xFF2D6A4F);
      case ComponentStatus.dueSoon:
        return const Color(0xFFF77F00);
      case ComponentStatus.overdue:
        return const Color(0xFFD62828);
    }
  }
}

/// Compară ultima schimbare a componentei cu intervalul recomandat și
/// kilometrajul curent al mașinii pentru a stabili starea acesteia.
ComponentStatus computeComponentStatus({
  required ComponentDefinition definition,
  required ComponentRecord? record,
  required int currentMileage,
}) {
  if (record == null ||
      (record.lastChangedDate == null && record.lastChangedMileage == null)) {
    return ComponentStatus.unset;
  }

  final intervalKm = record.customIntervalKm ?? definition.intervalKm;
  final intervalMonths = record.customIntervalMonths ?? definition.intervalMonths;

  double? kmRatio;
  if (intervalKm != null && record.lastChangedMileage != null) {
    final kmSince = currentMileage - record.lastChangedMileage!;
    kmRatio = kmSince / intervalKm;
  }

  double? monthRatio;
  if (intervalMonths != null && record.lastChangedDate != null) {
    final monthsSince = DateTime.now().difference(record.lastChangedDate!).inDays / 30.44;
    monthRatio = monthsSince / intervalMonths;
  }

  final ratios = [kmRatio, monthRatio].whereType<double>().toList();
  if (ratios.isEmpty) return ComponentStatus.unset;

  final maxRatio = ratios.reduce((a, b) => a > b ? a : b);
  if (maxRatio >= 1.0) return ComponentStatus.overdue;
  if (maxRatio >= 0.85) return ComponentStatus.dueSoon;
  return ComponentStatus.ok;
}
