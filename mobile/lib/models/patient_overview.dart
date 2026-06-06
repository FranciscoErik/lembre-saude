import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/models/user.dart';

class PatientOverview {
  const PatientOverview({
    required this.patient,
    required this.medications,
    required this.adherence,
  });

  final AppUser patient;
  final List<Medication> medications;
  final AdherenceSummary adherence;

  factory PatientOverview.fromJson(Map<String, dynamic> json) {
    return PatientOverview(
      patient: AppUser.fromJson(json['patient'] as Map<String, dynamic>),
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList(),
      adherence: AdherenceSummary.fromJson(json['adherence'] as Map<String, dynamic>),
    );
  }
}
