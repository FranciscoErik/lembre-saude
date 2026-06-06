import 'package:lembre_saude_mobile/models/user.dart';

class PatientLink {
  const PatientLink({
    required this.linkId,
    required this.patient,
    this.linkedAt,
  });

  final String linkId;
  final AppUser patient;
  final String? linkedAt;

  factory PatientLink.fromJson(Map<String, dynamic> json) {
    return PatientLink(
      linkId: json['linkId'] as String,
      patient: AppUser.fromJson(json['patient'] as Map<String, dynamic>),
      linkedAt: json['linkedAt'] as String?,
    );
  }
}
