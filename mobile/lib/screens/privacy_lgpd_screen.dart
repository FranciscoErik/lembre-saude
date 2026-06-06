import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/screens/caregiver/caregiver_shell.dart';
import 'package:lembre_saude_mobile/screens/patient/patient_shell.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

class PrivacyLgpdScreen extends StatefulWidget {
  const PrivacyLgpdScreen({super.key});

  @override
  State<PrivacyLgpdScreen> createState() => _PrivacyLgpdScreenState();
}

class _PrivacyLgpdScreenState extends State<PrivacyLgpdScreen> {
  bool _accepted = false;
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    final api = AppScope.of(context).api;

    try {
      await api.grantConsent('DATA_PROCESSING');
      final user = await api.authStorage.getUser();
      if (!mounted || user == null) return;

      final next = user.isCaregiver ? const CaregiverShell() : const PatientShell();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GreenHeader(
            title: 'Seus dados, seu controle.',
            subtitle: 'Consentimento LGPD',
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          _item(
                            Icons.medication_liquid,
                            'Dados de medicação',
                            'Nomes, doses e horários — usados só para lembrar e registrar adesão.',
                          ),
                          const Divider(height: 1),
                          _item(
                            Icons.notifications_active_outlined,
                            'Notificações',
                            'Alertas nos horários das doses e resumo diário.',
                          ),
                          const Divider(height: 1),
                          _item(
                            Icons.verified_user_outlined,
                            'Privacidade garantida',
                            'Seus dados não são compartilhados sem autorização explícita.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    title: const Text(
                      'Li e concordo com o tratamento dos meus dados para este serviço.',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.patientGreen,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Continuar',
                    isLoading: _isLoading,
                    onPressed: _accepted && !_isLoading ? _confirm : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.patientGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
