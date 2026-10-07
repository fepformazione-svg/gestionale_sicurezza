import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pages/home_page.dart';
import 'services/backup_service.dart';
import 'services/lan_app_bootstrap.dart';
import 'services/lan_client_runtime.dart';

import 'config/app_config.dart';
import 'pages/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  await BackupService.eseguiBackupAvvio();

  final lanRuntime = LanAppBootstrap.fromEnvironment(Platform.environment);

  runApp(MyApp(lanRuntime: lanRuntime));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.lanRuntime});

  final LanClientRuntime? lanRuntime;

  HomePage buildHomePage() {
    return HomePage(lanRuntime: lanRuntime);
  }

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
                  MaterialPageRoute(builder: (_) => buildHomePage()),
                );
              },
            )
          : buildHomePage(),
    );
  }
}
