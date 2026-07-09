import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class BackupSecondarioResult {
  final bool riuscito;
  final String? percorsoFile;
  final String messaggio;

  const BackupSecondarioResult({
    required this.riuscito,
    required this.percorsoFile,
    required this.messaggio,
  });
}

class BackupService {
  BackupService._();

  static const String _nomeFileConfigBackupSecondario =
      'backup_secondario_percorso.txt';

  static String? _basePath() {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null || userProfile.isEmpty) return null;

    return join(userProfile, 'Documents', 'Gestionale Sicurezza');
  }

  static String? percorsoBase() => _basePath();

  static String? percorsoDatabase() {
    final basePath = _basePath();
    if (basePath == null) return null;

    return join(basePath, 'gestionale_sicurezza.db');
  }

  static String? percorsoBackup() {
    final basePath = _basePath();
    if (basePath == null) return null;

    return join(basePath, 'Backup');
  }

  static String? percorsoExport() {
    final basePath = _basePath();
    if (basePath == null) return null;

    return join(basePath, 'Export');
  }

  static String? percorsoConfigBackupSecondario() {
    final basePath = _basePath();
    if (basePath == null) return null;

    return join(basePath, _nomeFileConfigBackupSecondario);
  }

  static String? percorsoBackupSecondarioConfigurato() {
    try {
      final configPath = percorsoConfigBackupSecondario();
      if (configPath == null) return null;

      final configFile = File(configPath);
      if (!configFile.existsSync()) return null;

      final percorso = configFile.readAsStringSync().trim();
      if (percorso.isEmpty) return null;

      return percorso;
    } catch (e) {
      debugPrint('ERRORE LETTURA CONFIG BACKUP SECONDARIO: $e');
      return null;
    }
  }

  static bool backupSecondarioRaggiungibile() {
    final percorso = percorsoBackupSecondarioConfigurato();
    if (percorso == null) return false;

    return Directory(percorso).existsSync();
  }

  static Future<void> salvaPercorsoBackupSecondario(String percorso) async {
    final basePath = _basePath();
    if (basePath == null) {
      throw Exception('Percorso base non disponibile.');
    }

    final baseDir = Directory(basePath);
    if (!baseDir.existsSync()) {
      await baseDir.create(recursive: true);
    }

    final configPath = percorsoConfigBackupSecondario();
    if (configPath == null) {
      throw Exception('File configurazione backup secondario non disponibile.');
    }

    await File(configPath).writeAsString(percorso.trim());
    debugPrint('BACKUP SECONDARIO CONFIGURATO: $percorso');
  }

  static Future<void> rimuoviPercorsoBackupSecondario() async {
    final configPath = percorsoConfigBackupSecondario();
    if (configPath == null) return;

    final configFile = File(configPath);
    if (configFile.existsSync()) {
      await configFile.delete();
    }

    debugPrint('CONFIG BACKUP SECONDARIO RIMOSSA');
  }

  static bool databaseEsistente() {
    final dbPath = percorsoDatabase();
    if (dbPath == null) return false;

    return File(dbPath).existsSync();
  }

  static int? dimensioneDatabaseBytes() {
    final dbPath = percorsoDatabase();
    if (dbPath == null) return null;

    final file = File(dbPath);
    if (!file.existsSync()) return null;

    return file.lengthSync();
  }

  static DateTime? ultimaModificaDatabase() {
    final dbPath = percorsoDatabase();
    if (dbPath == null) return null;

    final file = File(dbPath);
    if (!file.existsSync()) return null;

    return file.lastModifiedSync();
  }

  static Future<String?> eseguiBackupAvvio() async {
    return _eseguiBackup(silenzioso: true);
  }

  static Future<String?> eseguiBackupManuale() async {
    return _eseguiBackup(silenzioso: false);
  }

  static Future<BackupSecondarioResult> eseguiBackupSecondarioManuale() async {
    try {
      final dbPath = percorsoDatabase();
      if (dbPath == null) {
        return const BackupSecondarioResult(
          riuscito: false,
          percorsoFile: null,
          messaggio: 'Percorso database non disponibile.',
        );
      }

      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        return const BackupSecondarioResult(
          riuscito: false,
          percorsoFile: null,
          messaggio: 'Database operativo non trovato.',
        );
      }

      final percorsoSecondario = percorsoBackupSecondarioConfigurato();
      if (percorsoSecondario == null) {
        return const BackupSecondarioResult(
          riuscito: false,
          percorsoFile: null,
          messaggio: 'Backup secondario non configurato.',
        );
      }

      final directorySecondaria = Directory(percorsoSecondario);
      if (!directorySecondaria.existsSync()) {
        return const BackupSecondarioResult(
          riuscito: false,
          percorsoFile: null,
          messaggio:
              'Cartella backup secondario non raggiungibile. Verificare NAS, rete o percorso configurato.',
        );
      }

      final backupFile = join(
        percorsoSecondario,
        _nomeFileBackupConTimestamp(),
      );

      await dbFile.copy(backupFile);

      debugPrint('BACKUP SECONDARIO CREATO: $backupFile');

      return BackupSecondarioResult(
        riuscito: true,
        percorsoFile: backupFile,
        messaggio: 'Backup secondario creato correttamente.',
      );
    } catch (e) {
      debugPrint('ERRORE BACKUP SECONDARIO: $e');
      return BackupSecondarioResult(
        riuscito: false,
        percorsoFile: null,
        messaggio: 'Errore durante il backup secondario: $e',
      );
    }
  }

  static Future<String?> _eseguiBackup({required bool silenzioso}) async {
    try {
      final dbPath = percorsoDatabase();
      final backupPath = percorsoBackup();

      if (dbPath == null || backupPath == null) return null;

      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) return null;

      final backupDir = Directory(backupPath);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final backupFile = join(backupPath, _nomeFileBackupConTimestamp());

      await dbFile.copy(backupFile);

      if (!silenzioso) {
        debugPrint('BACKUP MANUALE CREATO: $backupFile');
      } else {
        debugPrint('BACKUP AVVIO CREATO: $backupFile');
      }

      return backupFile;
    } catch (e) {
      debugPrint('ERRORE BACKUP: $e');
      return null;
    }
  }

  static String _nomeFileBackupConTimestamp() {
    final now = DateTime.now();
    final data =
        '${now.year.toString().padLeft(4, '0')}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'backup_gestionale_sicurezza_$data.db';
  }
}
