import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/home_page.dart';
import 'services/backup_service.dart';

import 'config/app_config.dart';
import 'pages/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  await BackupService.eseguiBackupAvvio();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gestionale Sicurezza',
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        useMaterial3: true,
      ),
      home: AppConfig.loginObbligatorioAllAvvio
          ? LoginPage(
              onLoginRiuscito: () {
                navigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            )
          : const HomePage(),
    );
  }
}
