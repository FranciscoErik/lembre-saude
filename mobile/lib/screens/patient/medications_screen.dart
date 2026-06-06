import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/screens/patient/add_medication_screen.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/services/notification_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Medication> _medications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AppScope.of(context).api.getMedications();
      if (mounted) {
        setState(() {
          _medications = list;
          _loading = false;
        });
        await _syncNotifications(list);
      }
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
    } catch (_) {}
  }

  Future<void> _delete(Medication med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir medicamento?'),
        content: Text('Remover ${med.name} e suas doses associadas.'),
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
      await AppScope.of(context).api.deleteMedication(med.id);
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GreenHeader(title: 'Meus medicamentos', subtitle: 'Gerencie doses e horários'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.patientGreen))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _medications.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Nenhum medicamento cadastrado.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _medications.length,
                            itemBuilder: (_, i) {
                              final med = _medications[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE8F5EE),
                                    child: Icon(Icons.medication, color: AppColors.patientGreen),
                                  ),
                                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${med.dosage} · ${med.schedule} · ${med.frequency}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    onPressed: () => _delete(med),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (ok == true) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
