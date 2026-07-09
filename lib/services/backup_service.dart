import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class BackupService {
  BackupService._();

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

      final now = DateTime.now();
      final data =
          '${now.year.toString().padLeft(4, '0')}_'
          '${now.month.toString().padLeft(2, '0')}_'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final backupFile = join(
        backupPath,
        'backup_gestionale_sicurezza_$data.db',
      );

      await dbFile.copy(backupFile);

      debugPrint('BACKUP CREATO: $backupFile');
      return backupFile;
    } catch (e) {
      debugPrint('ERRORE BACKUP: $e');
      return null;
    }
  }
}
