import 'package:flutter/material.dart';
import 'package:lembre_saude_mobile/screens/caregiver/accept_link_screen.dart';
import 'package:lembre_saude_mobile/screens/caregiver/dashboard_screen.dart';
import 'package:lembre_saude_mobile/screens/patient/profile_screen.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';

class CaregiverShell extends StatefulWidget {
  const CaregiverShell({super.key});

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(caregiver: true),
      child: Builder(
        builder: (context) {
          final pages = [
            const CaregiverDashboardScreen(),
            const AcceptLinkScreen(),
            const ProfileScreen(),
          ];

          return Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
                NavigationDestination(
                  icon: Icon(Icons.link_outlined),
                  selectedIcon: Icon(Icons.link),
                  label: 'Vincular',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Perfil',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
