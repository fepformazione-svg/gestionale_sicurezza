import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class BackupService {
  BackupService._();

  static Future<void> eseguiBackupAvvio() async {
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null || userProfile.isEmpty) return;

      final basePath = join(userProfile, 'Documents', 'Gestionale Sicurezza');

      final dbPath = join(basePath, 'gestionale_sicurezza.db');
      final backupPath = join(basePath, 'Backup');

      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) return;

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
    } catch (e) {
      debugPrint('ERRORE BACKUP: $e');
    }
  }
}
