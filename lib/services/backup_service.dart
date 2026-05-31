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

  static Future<String?> eseguiBackupAvvio() async {
    return _eseguiBackup(silenzioso: true);
  }

  static Future<String?> eseguiBackupManuale() async {
    return _eseguiBackup(silenzioso: false);
  }

  static Future<String?> _eseguiBackup({required bool silenzioso}) async {
    try {
      final basePath = _basePath();
      if (basePath == null) return null;

      final dbPath = join(basePath, 'gestionale_sicurezza.db');
      final backupPath = join(basePath, 'Backup');

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
          '${now.minute.toString().padLeft(2, '0')}';

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
