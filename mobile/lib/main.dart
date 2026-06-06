import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lembre_saude_mobile/app_scope.dart';
import 'package:lembre_saude_mobile/screens/splash_screen.dart';
import 'package:lembre_saude_mobile/services/api_service.dart';
import 'package:lembre_saude_mobile/services/auth_storage.dart';
import 'package:lembre_saude_mobile/services/notification_service.dart';
import 'package:lembre_saude_mobile/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await NotificationService.instance.initialize();

  final authStorage = AuthStorage();
  final api = ApiService(authStorage: authStorage);

  runApp(LembreSaudeApp(api: api, authStorage: authStorage));
}

class LembreSaudeApp extends StatelessWidget {
  const LembreSaudeApp({
    super.key,
    required this.api,
    required this.authStorage,
  });

  final ApiService api;
  final AuthStorage authStorage;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: api,
      authStorage: authStorage,
      child: MaterialApp(
        title: 'Lembre Saúde',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('pt', 'BR'),
        home: const SplashScreen(),
      ),
    );
  }
}
