import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/dose.dart';
import 'package:lembre_saude_mobile/models/medication.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<DateTime, double> _rateByDay = {};
  List<Dose> _doses = [];
  Map<String, Medication> _meds = {};
  DateTime? _selectedDay;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = AppScope.of(context).api;
    final start = DateTime(_month.year, _month.month, 1);
    final end = DateTime(_month.year, _month.month + 1, 0);

    try {
      final meds = await api.getMedications();
      final adherence = await api.getAdherence(
        from: DateFormat('yyyy-MM-dd').format(start),
        to: DateFormat('yyyy-MM-dd').format(end.add(const Duration(days: 1))),
      );

      final byDay = <DateTime, List<Dose>>{};
      for (final dose in adherence.doses) {
        final raw = dose.createdAt ?? dose.scheduledTime;
        DateTime? day;
        try {
          day = DateTime.parse(raw).toLocal();
        } catch (_) {
          day = DateTime(_month.year, _month.month, DateTime.now().day);
        }
        final key = DateTime(day.year, day.month, day.day);
        byDay.putIfAbsent(key, () => []).add(dose);
      }

      final rates = <DateTime, double>{};
      byDay.forEach((day, doses) {
        final taken = doses.where((d) => d.isTaken).length;
        rates[day] = doses.isEmpty ? 0 : taken / doses.length;
      });

      if (!mounted) return;
      setState(() {
        _meds = {for (final m in meds) m.id: m};
        _doses = adherence.doses;
        _rateByDay = rates;
        _loading = false;
        _selectedDay ??= DateTime.now();
        if (_selectedDay!.month != _month.month) {
          _selectedDay = DateTime(_month.year, _month.month, 1);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
    _load();
  }

  List<Dose> _dosesForDay(DateTime day) {
    return _doses.where((d) {
      final raw = d.createdAt ?? '';
      try {
        final dt = DateTime.parse(raw).toLocal();
        return dt.year == day.year && dt.month == day.month && dt.day == day.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Color _colorForRate(double rate) {
    if (rate >= 0.9) return AppColors.success;
    if (rate >= 0.5) return AppColors.warning;
    if (rate > 0) return AppColors.danger;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM('pt_BR').format(_month);
    final selected = _selectedDay;
    final dayDoses = selected != null ? _dosesForDay(selected) : <Dose>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GreenHeader(title: 'Histórico', subtitle: 'Aderência mensal'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(monthLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.patientGreen))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildLegend(),
                      const SizedBox(height: 12),
                      _buildCalendar(),
                      const SizedBox(height: 20),
                      if (selected != null) ...[
                        Text(
                          DateFormat('d MMMM', 'pt_BR').format(selected),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (dayDoses.isEmpty)
                          const Text('Nenhuma dose registrada neste dia.',
                              style: TextStyle(color: AppColors.textSecondary))
                        else
                          ...dayDoses.map((d) {
                            final med = _meds[d.medicationId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  d.isTaken ? Icons.check_circle : Icons.cancel,
                                  color: d.isTaken ? AppColors.success : AppColors.danger,
                                ),
                                title: Text(med?.name ?? 'Medicamento'),
                                subtitle: Text(
                                  d.isTaken
                                      ? 'Tomada${d.confirmedAt != null ? ' · ${DateFormat.Hm().format(DateTime.parse(d.confirmedAt!).toLocal())}' : ''}'
                                      : 'Status: ${d.status}',
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _LegendDot(color: AppColors.success, label: 'Tomado'),
        _LegendDot(color: AppColors.warning, label: 'Parcial'),
        _LegendDot(color: AppColors.danger, label: 'Perdido'),
      ],
    );
  }

  Widget _buildCalendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday;

    final cells = <Widget>[];
    const weekdays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    for (final w in weekdays) {
      cells.add(Center(child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
    }

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final rate = _rateByDay[date] ?? 0;
      final selected = _selectedDay != null &&
          _selectedDay!.year == date.year &&
          _selectedDay!.month == date.month &&
          _selectedDay!.day == date.day;

      cells.add(GestureDetector(
        onTap: () => setState(() => _selectedDay = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _colorForRate(rate),
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: AppColors.patientGreen, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: rate > 0 ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
