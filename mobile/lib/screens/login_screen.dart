import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/models/user.dart';
import 'package:lembre_saude_mobile/screens/caregiver/caregiver_shell.dart';
import 'package:lembre_saude_mobile/screens/patient/patient_shell.dart';
import 'package:lembre_saude_mobile/screens/privacy_lgpd_screen.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/app_card.dart';
import 'package:lembre_saude_mobile/widgets/green_header.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.isRegister});

  final bool isRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'PATIENT';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final api = AppScope.of(context).api;

    try {
      final AuthResponse auth;
      if (widget.isRegister) {
        auth = await api.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
      } else {
        auth = await api.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      await api.saveAuth(auth);
      if (!mounted) return;

      final hasConsent = await api.hasLgpdConsent();
      if (!mounted) return;

      final Widget next;
      if (!hasConsent) {
        next = const PrivacyLgpdScreen();
      } else if (auth.user.isCaregiver) {
        next = const CaregiverShell();
      } else {
        next = const PatientShell();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sem conexão com a API ($e). '
            'Confira se o PC está com npm run dev e na mesma Wi‑Fi.',
          ),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRegister ? 'Criar conta' : 'Entrar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GreenHeader(
            title: title,
            subtitle: widget.isRegister
                ? 'Comece a cuidar da sua saúde hoje'
                : 'Bem-vindo de volta',
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: AppCard(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isRegister) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              v == null || v.trim().length < 2 ? 'Informe seu nome' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Eu sou:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'PATIENT', label: Text('Paciente')),
                            ButtonSegment(value: 'CAREGIVER', label: Text('Cuidador')),
                          ],
                          selected: {_role},
                          onSelectionChanged: (s) => setState(() => _role = s.first),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o e-mail';
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Mínimo de 6 caracteres' : null,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: widget.isRegister ? 'Criar conta' : 'Entrar',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
