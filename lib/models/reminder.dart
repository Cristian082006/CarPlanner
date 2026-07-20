/// Reminder manual, creat direct de utilizator (nu unul derivat automat
/// dintr-un document sau o revizie).
class Reminder {
  final String id;
  final String title;
  final DateTime date;
  final String? notes;
  final String? vehicleId;

  Reminder({
    required this.id,
    required this.title,
    required this.date,
    this.notes,
    this.vehicleId,
  });

  Reminder copyWith({
    String? title,
    DateTime? date,
    String? notes,
    String? vehicleId,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'vehicleId': vehicleId,
    };
  }

  factory Reminder.fromMap(Map<String, Object?> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      vehicleId: map['vehicleId'] as String?,
    );
  }
}
