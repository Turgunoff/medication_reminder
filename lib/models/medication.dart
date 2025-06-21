class Medication {
  final int? id;
  final String name;
  final String dosage;
  final int frequency;
  final String times; // JSON string of times
  final String? notes;
  final DateTime createdAt;
  final bool isActive;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    this.notes,
    required this.createdAt,
    this.isActive = true,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Create from Map from database
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      times: map['times'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  // Copy with method for updating
  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    int? frequency,
    String? times,
    String? notes,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
