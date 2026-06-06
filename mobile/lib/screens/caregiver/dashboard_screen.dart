import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/patient_overview.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/adherence_card.dart';
import 'package:lembre_saude_mobile/widgets/app_card.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  List<PatientOverview> _overviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = AppScope.of(context).api;
      final links = await api.getLinkedPatients();
      final overviews = await Future.wait(
        links.map((l) => api.getPatientOverview(l.patient.id)),
      );
      if (mounted) {
        setState(() {
          _overviews = overviews;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.caregiverBlue,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreenHeader(
                title: 'Modo Cuidador',
                subtitle: 'Medicamentos e aderência dos pacientes vinculados',
                caregiverMode: true,
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.caregiverBlue)),
              )
            else if (_overviews.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: AppColors.caregiverBlue.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum paciente vinculado',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use a aba "Vincular" para aceitar um código do paciente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _PatientOverviewCard(overview: _overviews[i]),
                    childCount: _overviews.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientOverviewCard extends StatelessWidget {
  const _PatientOverviewCard({required this.overview});

  final PatientOverview overview;

  @override
  Widget build(BuildContext context) {
    final linked = overview.patient.name;
    final adherence = overview.adherence;
    final meds = overview.medications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.caregiverBlue.withOpacity(0.12),
                child: Text(
                  linked.isNotEmpty ? linked[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.caregiverBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.patient.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      overview.patient.email,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (adherence.pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        ),
        AdherenceCard(
          percent: adherence.adherenceRate,
          taken: adherence.taken,
          total: adherence.total,
          caregiverMode: true,
          title: 'Aderência do paciente',
        ),
        const SizedBox(height: 16),
        const Text(
          'Medicamentos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (meds.isEmpty)
          const AppCard(
            padding: EdgeInsets.all(20),
            child: Text(
              'Nenhum medicamento cadastrado ainda.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...meds.map(
            (med) => AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.caregiverBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, color: AppColors.caregiverBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '${med.dosage} · ${med.schedule}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    med.active ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                      color: med.active ? AppColors.success : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
