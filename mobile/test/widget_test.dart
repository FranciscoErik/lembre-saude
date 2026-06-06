import 'package:flutter_test/flutter_test.dart';
import 'package:lembre_saude_mobile/models/dose.dart';

void main() {
  test('AdherenceSummary parseia resposta da API', () {
    final summary = AdherenceSummary.fromJson({
      'adherenceRate': 75,
      'summary': {'total': 4, 'taken': 3, 'pending': 1, 'skipped': 0, 'postponed': 0},
      'doses': [
        {
          'id': '1',
          'medicationId': 'm1',
          'scheduledTime': '08:00',
          'status': 'TAKEN',
        },
      ],
    });

    expect(summary.adherenceRate, 75);
    expect(summary.taken, 3);
    expect(summary.doses.first.isTaken, true);
  });
}
