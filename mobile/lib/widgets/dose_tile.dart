import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/app_card.dart';

class DoseTile extends StatelessWidget {
  const DoseTile({
    super.key,
    required this.dose,
    required this.medication,
    this.onConfirm,
    this.onPostpone,
  });

  final Dose dose;
  final Medication? medication;
  final VoidCallback? onConfirm;
  final VoidCallback? onPostpone;

  @override
  Widget build(BuildContext context) {
    final name = medication?.name ?? 'Medicamento';
    final dosage = medication?.dosage ?? '';
    final time = medication?.schedule ?? dose.scheduledTime;
    final isTaken = dose.isTaken;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.patientGreen.withOpacity(0.15),
                  AppColors.patientGreenLight.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_liquid, color: AppColors.patientGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  dosage.isNotEmpty ? '$dosage · $time' : time,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 4),
                  Text('Tomado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.caregiverBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.patientGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
