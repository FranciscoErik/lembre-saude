import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

enum DoseAction { taken, postponed }

class DoseConfirmSheet extends StatelessWidget {
  const DoseConfirmSheet({
    super.key,
    required this.dose,
    this.medication,
  });

  final Dose dose;
  final Medication? medication;

  @override
  Widget build(BuildContext context) {
    final name = medication?.name ?? 'Medicamento';
    final dosage = medication?.dosage ?? '';
    final time = medication?.schedule ?? dose.scheduledTime;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.patientGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppColors.patientGreen),
                    SizedBox(width: 10),
                    Text(
                      'Hora do seu remédio',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '$dosage · $time',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: '✅  Sim, tomei agora!',
                onPressed: () => Navigator.pop(context, DoseAction.taken),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '⏰  Adiar 30 minutos',
                backgroundColor: AppColors.warning.withOpacity(0.12),
                foregroundColor: AppColors.warning,
                onPressed: () => Navigator.pop(context, DoseAction.postponed),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ],
          ),
        ),
      ),
    );
  }
}
