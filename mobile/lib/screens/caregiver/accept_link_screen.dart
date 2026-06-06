import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

class AcceptLinkScreen extends StatefulWidget {
  const AcceptLinkScreen({super.key});

  @override
  State<AcceptLinkScreen> createState() => _AcceptLinkScreenState();
}

class _AcceptLinkScreenState extends State<AcceptLinkScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final patient = await AppScope.of(context).api.acceptInvite(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vinculado a ${patient.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
      _codeController.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GreenHeader(
            title: 'Vincular paciente',
            subtitle: 'Digite o código enviado pelo paciente',
            caregiverMode: true,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código de convite',
                    hintText: 'Ex: ABC123',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Aceitar vínculo',
                  isLoading: _loading,
                  onPressed: _accept,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
