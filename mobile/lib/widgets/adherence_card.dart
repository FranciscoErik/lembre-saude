import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/app_card.dart';

class AdherenceCard extends StatelessWidget {
  const AdherenceCard({
    super.key,
    required this.percent,
    required this.taken,
    required this.total,
    this.caregiverMode = false,
    this.title = 'Aderência de hoje',
  });

  final int percent;
  final int taken;
  final int total;
  final bool caregiverMode;
  final String title;

  Color get _primary =>
      caregiverMode ? AppColors.caregiverBlue : AppColors.patientGreen;

  Color get _primaryLight =>
      caregiverMode ? AppColors.caregiverBlue : AppColors.patientGreenLight;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : taken / total;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$taken de $total doses',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE8F0EB),
                    color: _primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: const Color(0xFFE8F0EB),
                  color: _primaryLight,
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
