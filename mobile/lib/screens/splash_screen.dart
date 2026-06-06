import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/screens/caregiver/caregiver_shell.dart';
import 'package:lembre_saude_mobile/screens/onboarding_screen.dart';
import 'package:lembre_saude_mobile/screens/patient/patient_shell.dart';
import 'package:lembre_saude_mobile/screens/privacy_lgpd_screen.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';
import 'package:lembre_saude_mobile/widgets/pill_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final api = AppScope.of(context).api;
    final auth = AppScope.of(context).authStorage;

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final hasSession = await auth.hasSession();
    if (!hasSession) {
      _go(const OnboardingScreen());
      return;
    }

    try {
      final user = await api.getProfile();
      await auth.saveSession(token: (await auth.getToken())!, user: user);

      final hasConsent = await api.hasLgpdConsent();
      if (!mounted) return;

      if (!hasConsent) {
        _go(const PrivacyLgpdScreen());
        return;
      }

      _go(user.isCaregiver ? const CaregiverShell() : const PatientShell());
    } catch (_) {
      await auth.clear();
      if (mounted) _go(const OnboardingScreen());
    }
  }

  void _go(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.patientGreen, AppColors.patientGreenDark],
          ),
        ),
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PillLogo(size: 100),
                const SizedBox(height: 28),
                const Text(
                  'Lembre Saúde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
