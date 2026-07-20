import '../utils/constants.dart';

/// Un document de tip RCA, CASCO, Rovinietă, ITP, Asigurare locuință sau altul.
/// [vehicleId] este null pentru documente care nu țin de o mașină anume
/// (ex: asigurarea locuinței).
class CarDocument {
  final String id;
  final String? vehicleId;
  final DocumentType type;
  final String? title;
  final String? provider;
  final String? policyNumber;
  final DateTime? startDate;
  final DateTime expiryDate;
  final double? cost;
  final String? notes;
  final String? photoPath;

  CarDocument({
    required this.id,
    this.vehicleId,
    required this.type,
    this.title,
    this.provider,
    this.policyNumber,
    this.startDate,
    required this.expiryDate,
    this.cost,
    this.notes,
    this.photoPath,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;

  CarDocument copyWith({
    String? vehicleId,
    DocumentType? type,
    String? title,
    String? provider,
    String? policyNumber,
    DateTime? startDate,
    DateTime? expiryDate,
    double? cost,
    String? notes,
    String? photoPath,
  }) {
    return CarDocument(
      id: id,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      title: title ?? this.title,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.name,
      'title': title,
      'provider': provider,
      'policyNumber': policyNumber,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'cost': cost,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  factory CarDocument.fromMap(Map<String, Object?> map) {
    return CarDocument(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String?,
      type: DocumentTypeX.fromName(map['type'] as String),
      title: map['title'] as String?,
      provider: map['provider'] as String?,
      policyNumber: map['policyNumber'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      cost: (map['cost'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }
}
