import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/user.dart';
import 'package:lembre_saude_mobile/screens/onboarding_screen.dart';
import 'package:lembre_saude_mobile/models/notification_settings.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/services/notification_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  String? _inviteCode;
  bool _loadingInvite = false;
  NotificationSettings? _notifSettings;
  bool _loadingNotif = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNotificationSettings();
  }

  Future<void> _loadUser() async {
    final user = await AppScope.of(context).api.authStorage.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _loadNotificationSettings() async {
    if (_user?.isPatient != true && mounted) {
      final user = await AppScope.of(context).api.authStorage.getUser();
      if (user?.isPatient != true) return;
    }
    try {
      final settings = await AppScope.of(context).api.getNotificationSettings();
      if (mounted) setState(() => _notifSettings = settings);
    } catch (_) {}
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() => _loadingNotif = true);
    try {
      final api = AppScope.of(context).api;
      final updated = await api.updateNotificationSettings(enabled: enabled);
      if (!mounted) return;
      setState(() => _notifSettings = updated);

      if (NotificationService.isSupported) {
        if (enabled) {
          final meds = await api.getMedications();
          await NotificationService.instance.syncMedications(
            meds,
            enabled: true,
            remindBeforeMinutes: updated.remindBeforeMinutes,
          );
        } else {
          await NotificationService.instance.cancelAll();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Lembretes ativados nos horários dos medicamentos.'
                : 'Lembretes desativados.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loadingNotif = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _loadingInvite = true);
    try {
      final code = await AppScope.of(context).api.createInviteCode();
      if (mounted) setState(() => _inviteCode = code);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loadingInvite = false);
    }
  }

  Future<void> _logout() async {
    await AppScope.of(context).authStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text('Esta ação é irreversível (LGPD). Todos os dados serão removidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = AppScope.of(context).api;
      await api.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GreenHeader(
            title: user?.name ?? 'Perfil',
            subtitle: user?.email,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge_outlined, color: AppColors.patientGreen),
                    title: const Text('Tipo de conta'),
                    subtitle: Text(user?.isPatient == true ? 'Paciente' : 'Cuidador'),
                  ),
                ),
                if (user?.isPatient == true) ...[
                  const SizedBox(height: 16),
                  const Text('Notificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (!NotificationService.isSupported)
                    const Text(
                      'Lembretes locais disponíveis no app Android ou iOS.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    )
                  else
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lembretes de medicamentos'),
                      subtitle: const Text('Alerta diário no horário cadastrado (ex: 08:00)'),
                      value: _notifSettings?.enabled ?? true,
                      onChanged: _loadingNotif ? null : _toggleNotifications,
                      activeThumbColor: AppColors.patientGreen,
                    ),
                  const SizedBox(height: 16),
                  const Text('Vincular cuidador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text(
                    'Gere um código e envie para quem vai acompanhar sua adesão.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (_inviteCode != null)
                    Card(
                      color: const Color(0xFFE8F5EE),
                      child: ListTile(
                        title: Text(
                          _inviteCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.patientGreen,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _inviteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Código copiado!')),
                            );
                          },
                        ),
                      ),
                    ),
                  PrimaryButton(
                    label: _loadingInvite ? 'Gerando...' : 'Gerar código de convite',
                    isLoading: _loadingInvite,
                    onPressed: _loadingInvite ? null : _generateInvite,
                  ),
                  const SizedBox(height: 24),
                ],
                OutlinedButton(
                  onPressed: _logout,
                  child: const Text('Sair da conta'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _deleteAccount,
                  child: const Text('Excluir minha conta', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
