/// Ultima schimbare înregistrată pentru un component esențial al unei
/// mașini anume (id-ul componentei vine din catalogul static
/// [essentialComponents]).
class ComponentRecord {
  final String vehicleId;
  final String componentId;
  final DateTime? lastChangedDate;
  final int? lastChangedMileage;
  final String? notes;
  /// Interval personalizat, aplicat printr-un profil de mentenanță pe marcă
  /// (vezi `maintenance_profiles.dart`) — dacă e null, se folosește intervalul
  /// generic din [ComponentDefinition].
  final int? customIntervalKm;
  final int? customIntervalMonths;
  /// Numele mărcii al cărei profil a setat intervalul personalizat, pentru
  /// afișare ("Interval personalizat — Dacia").
  final String? customIntervalSource;

  ComponentRecord({
    required this.vehicleId,
    required this.componentId,
    this.lastChangedDate,
    this.lastChangedMileage,
    this.notes,
    this.customIntervalKm,
    this.customIntervalMonths,
    this.customIntervalSource,
  });

  /// Id determinist ca să existe cel mult o înregistrare per
  /// (mașină, component) — o salvare nouă suprascrie automat o pornire.
  String get id => '${vehicleId}_$componentId';

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'componentId': componentId,
      'lastChangedDate': lastChangedDate?.toIso8601String(),
      'lastChangedMileage': lastChangedMileage,
      'notes': notes,
      'customIntervalKm': customIntervalKm,
      'customIntervalMonths': customIntervalMonths,
      'customIntervalSource': customIntervalSource,
    };
  }

  factory ComponentRecord.fromMap(Map<String, Object?> map) {
    return ComponentRecord(
      vehicleId: map['vehicleId'] as String,
      componentId: map['componentId'] as String,
      lastChangedDate: map['lastChangedDate'] != null
          ? DateTime.parse(map['lastChangedDate'] as String)
          : null,
      lastChangedMileage: map['lastChangedMileage'] as int?,
      notes: map['notes'] as String?,
      customIntervalKm: map['customIntervalKm'] as int?,
      customIntervalMonths: map['customIntervalMonths'] as int?,
      customIntervalSource: map['customIntervalSource'] as String?,
    );
  }
}
