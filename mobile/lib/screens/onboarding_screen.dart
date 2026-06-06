import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/screens/login_screen.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/pill_logo.dart';
import 'package:lembre_saude_mobile/widgets/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.patientGreen, AppColors.patientGreenDark],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const PillLogo(size: 110),
                const SizedBox(height: 32),
                const Text(
                  'Lembre Saúde',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nunca mais esqueça seus medicamentos.\nSimples, seguro e acessível.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const Spacer(flex: 3),
                PrimaryButton(
                  label: 'Criar minha conta',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.patientGreen,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(isRegister: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Já tenho conta',
                  outlined: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(isRegister: false),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
