import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openLanReadOnlyDatabase(String databasePath) async {
  final file = File(databasePath);

  if (!await file.exists()) {
    throw FileSystemException('Database non trovato.', databasePath);
  }

  sqfliteFfiInit();

  return databaseFactoryFfi.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
}
