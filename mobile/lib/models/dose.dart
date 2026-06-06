class Dose {
  const Dose({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    required this.status,
    this.confirmedAt,
    this.createdAt,
  });

  final String id;
  final String medicationId;
  final String scheduledTime;
  final String status;
  final String? confirmedAt;
  final String? createdAt;

  bool get isTaken => status == 'TAKEN';
  bool get isPending => status == 'PENDING';
  bool get isPostponed => status == 'POSTPONED';

  factory Dose.fromJson(Map<String, dynamic> json) {
    return Dose(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      scheduledTime: json['scheduledTime'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      confirmedAt: json['confirmedAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class AdherenceSummary {
  const AdherenceSummary({
    required this.total,
    required this.taken,
    required this.pending,
    required this.skipped,
    required this.postponed,
    required this.adherenceRate,
    required this.doses,
  });

  final int total;
  final int taken;
  final int pending;
  final int skipped;
  final int postponed;
  final int adherenceRate;
  final List<Dose> doses;

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return AdherenceSummary(
      total: summary['total'] as int? ?? 0,
      taken: summary['taken'] as int? ?? 0,
      pending: summary['pending'] as int? ?? 0,
      skipped: summary['skipped'] as int? ?? 0,
      postponed: summary['postponed'] as int? ?? 0,
      adherenceRate: json['adherenceRate'] as int? ?? 0,
      doses: (json['doses'] as List<dynamic>? ?? [])
          .map((e) => Dose.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
