class ServiceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int? mileage;
  final String title;
  final String? description;
  final double? cost;
  final String? workshop;
  final DateTime? nextServiceDate;
  final int? nextServiceMileage;
  final String? photoPath;
  final List<String> changedComponentIds;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.mileage,
    required this.title,
    this.description,
    this.cost,
    this.workshop,
    this.nextServiceDate,
    this.nextServiceMileage,
    this.photoPath,
    this.changedComponentIds = const [],
  });

  ServiceRecord copyWith({
    DateTime? date,
    int? mileage,
    String? title,
    String? description,
    double? cost,
    String? workshop,
    DateTime? nextServiceDate,
    int? nextServiceMileage,
    String? photoPath,
    List<String>? changedComponentIds,
  }) {
    return ServiceRecord(
      id: id,
      vehicleId: vehicleId,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      workshop: workshop ?? this.workshop,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      photoPath: photoPath ?? this.photoPath,
      changedComponentIds: changedComponentIds ?? this.changedComponentIds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'title': title,
      'description': description,
      'cost': cost,
      'workshop': workshop,
      'nextServiceDate': nextServiceDate?.toIso8601String(),
      'nextServiceMileage': nextServiceMileage,
      'photoPath': photoPath,
      'changedComponentIds': changedComponentIds.join(','),
    };
  }

  factory ServiceRecord.fromMap(Map<String, Object?> map) {
    final changedComponentIdsRaw = map['changedComponentIds'] as String?;
    return ServiceRecord(
      id: map['id'] as String,
      vehicleId: map['vehicleId'] as String,
      date: DateTime.parse(map['date'] as String),
      mileage: map['mileage'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      cost: (map['cost'] as num?)?.toDouble(),
      workshop: map['workshop'] as String?,
      nextServiceDate: map['nextServiceDate'] != null
          ? DateTime.parse(map['nextServiceDate'] as String)
          : null,
      nextServiceMileage: map['nextServiceMileage'] as int?,
      photoPath: map['photoPath'] as String?,
      changedComponentIds: (changedComponentIdsRaw == null || changedComponentIdsRaw.isEmpty)
          ? const []
          : changedComponentIdsRaw.split(','),
    );
  }
}
