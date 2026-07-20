class Vehicle {
  final String id;
  final String name;
  final String make;
  final String model;
  final int? year;
  final String plateNumber;
  final String? vin;
  final String? fuelType;
  final String? engineCode;
  final int mileage;
  final String? photoPath;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.make,
    required this.model,
    this.year,
    required this.plateNumber,
    this.vin,
    this.fuelType,
    this.engineCode,
    this.mileage = 0,
    this.photoPath,
    required this.createdAt,
  });

  Vehicle copyWith({
    String? name,
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    String? vin,
    String? fuelType,
    String? engineCode,
    int? mileage,
    String? photoPath,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: vin ?? this.vin,
      fuelType: fuelType ?? this.fuelType,
      engineCode: engineCode ?? this.engineCode,
      mileage: mileage ?? this.mileage,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'vin': vin,
      'fuelType': fuelType,
      'engineCode': engineCode,
      'mileage': mileage,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as String,
      name: map['name'] as String,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int?,
      plateNumber: map['plateNumber'] as String,
      vin: map['vin'] as String?,
      fuelType: map['fuelType'] as String?,
      engineCode: map['engineCode'] as String?,
      mileage: map['mileage'] as int? ?? 0,
      photoPath: map['photoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
