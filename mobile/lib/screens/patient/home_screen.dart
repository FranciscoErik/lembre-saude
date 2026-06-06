import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/screens/patient/add_medication_screen.dart';
import 'package:lembre_saude_mobile/screens/patient/dose_confirm_sheet.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/services/notification_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/adherence_card.dart';
import 'package:lembre_saude_mobile/widgets/dose_tile.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _userName;
  AdherenceSummary? _adherence;
  Map<String, Medication> _medsById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = AppScope.of(context).api;

    try {
      final user = await api.authStorage.getUser();
      final meds = await api.getMedications();
      final adherence = await api.getAdherence();

      if (!mounted) return;
      setState(() {
        _userName = user?.name ?? 'Paciente';
        _medsById = {for (final m in meds) m.id: m};
        _adherence = adherence;
        _loading = false;
      });
      await _syncNotifications(meds);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _syncNotifications(List<Medication> meds) async {
    if (!NotificationService.isSupported) return;
    try {
      final settings = await AppScope.of(context).api.getNotificationSettings();
      await NotificationService.instance.syncMedications(
        meds,
        enabled: settings.enabled,
        remindBeforeMinutes: settings.remindBeforeMinutes,
      );
    } catch (_) {
      // Preferências opcionais; lembretes locais seguem sem bloquear a tela.
    }
  }

  Future<void> _openConfirm(Dose dose) async {
    final med = _medsById[dose.medicationId];
    final action = await showModalBottomSheet<DoseAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoseConfirmSheet(dose: dose, medication: med),
    );

    if (action == null || !mounted) return;

    final api = AppScope.of(context).api;
    try {
      final status = action == DoseAction.taken ? 'TAKEN' : 'POSTPONED';
      await api.confirmDose(dose.id, status: status);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == DoseAction.taken ? 'Dose confirmada!' : 'Dose adiada.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Paciente';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(DateTime.now());
    final adherence = _adherence;
    final firstName = _firstName(_userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GreenHeader(
                title: '${_greeting()}, $firstName 👋',
                subtitle: today,
                trailing: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.patientGreen)),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: AdherenceCard(
                    percent: adherence?.adherenceRate ?? 0,
                    taken: adherence?.taken ?? 0,
                    total: adherence?.total ?? 0,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        const Text(
                          'Lembretes de hoje',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (adherence != null && adherence.pending > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${adherence.pending} pendente${adherence.pending > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (adherence == null || adherence.doses.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Nenhum lembrete hoje. Cadastre um medicamento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...adherence.doses.map(
                        (dose) => DoseTile(
                          dose: dose,
                          medication: _medsById[dose.medicationId],
                          onConfirm: dose.isTaken ? null : () => _openConfirm(dose),
                          onPostpone: dose.isTaken
                              ? null
                              : () => _openConfirm(dose),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
