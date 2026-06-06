class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.frequency,
    required this.active,
  });

  final String id;
  final String name;
  final String dosage;
  final String schedule;
  final String frequency;
  final bool active;

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      schedule: json['schedule'] as String,
      frequency: json['frequency'] as String,
      active: json['active'] as bool? ?? true,
    );
  }
}
