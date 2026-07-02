import 'dart:convert';
import 'dart:io';

class ComuneEntry {
  ComuneEntry({
    required this.nome,
    required this.provincia,
    required this.codiceCatastale,
    required this.chiave,
  });

  final String nome;
  final String provincia;
  final String codiceCatastale;
  final String chiave;
}

void main() {
  final input = File('tools/istat_comuni.csv');

  if (!input.existsSync()) {
    stderr.writeln('File non trovato: tools/istat_comuni.csv');
    exitCode = 1;
    return;
  }

  final bytes = input.readAsBytesSync();

  String contenuto;
  try {
    contenuto = utf8.decode(bytes);
  } catch (_) {
    contenuto = latin1.decode(bytes);
  }

  contenuto = contenuto.replaceFirst('\uFEFF', '');

  final recordsSemicolon = parseCsv(contenuto, ';');
  final recordsComma = parseCsv(contenuto, ',');

  final records =
      recordsSemicolon.isNotEmpty &&
          recordsSemicolon.first.length >= recordsComma.first.length
      ? recordsSemicolon
      : recordsComma;

  if (records.isEmpty) {
    stderr.writeln('CSV vuoto.');
    exitCode = 1;
    return;
  }

  final intestazioni = records.first;

  final indiceNome = findHeaderIndex(
    intestazioni,
    (header) => header.contains('denominazione in italiano'),
  );

  final indiceCodice = findHeaderIndex(
    intestazioni,
    (header) => header.contains('codice catastale'),
  );

  final indiceProvincia = findHeaderIndex(
    intestazioni,
    (header) => header.contains('sigla automobilistica'),
  );

  if (indiceNome < 0 || indiceCodice < 0) {
    stderr.writeln('Colonne richieste non trovate nel CSV ISTAT.');
    stderr.writeln('Colonne disponibili:');
    for (final intestazione in intestazioni) {
      stderr.writeln('- $intestazione');
    }
    exitCode = 1;
    return;
  }

  final entries = <ComuneEntry>[];

  for (var i = 1; i < records.length; i++) {
    final celle = records[i];

    if (celle.length <= indiceNome || celle.length <= indiceCodice) {
      continue;
    }

    final nome = celle[indiceNome].trim();
    final codice = celle[indiceCodice].trim().toUpperCase();
    final provincia = indiceProvincia >= 0 && celle.length > indiceProvincia
        ? celle[indiceProvincia].trim().toUpperCase()
        : '';

    if (nome.isEmpty || codice.isEmpty) {
      continue;
    }

    if (!RegExp(r'^[A-Z][0-9]{3}$').hasMatch(codice)) {
      continue;
    }

    entries.add(
      ComuneEntry(
        nome: nome,
        provincia: provincia,
        codiceCatastale: codice,
        chiave: normalizzaChiave(nome),
      ),
    );
  }

  entries.sort((a, b) {
    final confrontoChiave = a.chiave.compareTo(b.chiave);
    if (confrontoChiave != 0) {
      return confrontoChiave;
    }
    return a.provincia.compareTo(b.provincia);
  });

  final gruppi = <String, List<ComuneEntry>>{};

  for (final entry in entries) {
    gruppi.putIfAbsent(entry.chiave, () => <ComuneEntry>[]).add(entry);
  }

  final gruppiUnivoci =
      gruppi.entries.where((entry) => entry.value.length == 1).toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  final gruppiAmbigui =
      gruppi.entries.where((entry) => entry.value.length > 1).toList()
        ..sort((a, b) => a.key.compareTo(b.key));

  final output = StringBuffer();

  output.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
  output.writeln(
    '// Generated from tools/istat_comuni.csv by tools/genera_codici_catastali.dart.',
  );
  output.writeln();

  output.writeln('class ComuneCatastaleItaliano {');
  output.writeln('  const ComuneCatastaleItaliano({');
  output.writeln('    required this.nome,');
  output.writeln('    required this.provincia,');
  output.writeln('    required this.codiceCatastale,');
  output.writeln('  });');
  output.writeln();
  output.writeln('  final String nome;');
  output.writeln('  final String provincia;');
  output.writeln('  final String codiceCatastale;');
  output.writeln('}');
  output.writeln();

  output.writeln(
    'const Map<String, String> codiciCatastaliComuniItaliani = <String, String>{',
  );

  for (final gruppo in gruppiUnivoci) {
    final entry = gruppo.value.single;
    output.writeln(
      '  ${dartString(gruppo.key)}: ${dartString(entry.codiceCatastale)},',
    );
  }

  output.writeln('};');
  output.writeln();

  output.writeln(
    'const Map<String, List<ComuneCatastaleItaliano>> comuniCatastaliItalianiAmbigui = <String, List<ComuneCatastaleItaliano>>{',
  );

  for (final gruppo in gruppiAmbigui) {
    output.writeln('  ${dartString(gruppo.key)}: <ComuneCatastaleItaliano>[');

    for (final entry in gruppo.value) {
      output.writeln(
        '    ComuneCatastaleItaliano(nome: ${dartString(entry.nome)}, provincia: ${dartString(entry.provincia)}, codiceCatastale: ${dartString(entry.codiceCatastale)}),',
      );
    }

    output.writeln('  ],');
  }

  output.writeln('};');
  output.writeln();

  Directory('lib/data').createSync(recursive: true);
  File(
    'lib/data/codici_catastali_comuni.dart',
  ).writeAsStringSync(output.toString());

  stdout.writeln('Archivio generato: lib/data/codici_catastali_comuni.dart');
  stdout.writeln('Comuni importati: ${entries.length}');
  stdout.writeln('Nomi univoci: ${gruppiUnivoci.length}');
  stdout.writeln('Nomi ambigui: ${gruppiAmbigui.length}');
}

int findHeaderIndex(
  List<String> intestazioni,
  bool Function(String headerNormalizzato) test,
) {
  for (var i = 0; i < intestazioni.length; i++) {
    final header = normalizzaChiave(intestazioni[i]).toLowerCase();
    if (test(header)) {
      return i;
    }
  }

  return -1;
}

List<List<String>> parseCsv(String text, String separator) {
  final records = <List<String>>[];
  var record = <String>[];
  final field = StringBuffer();

  var inQuotes = false;
  final separatorCode = separator.codeUnitAt(0);

  for (var i = 0; i < text.length; i++) {
    final charCode = text.codeUnitAt(i);

    if (charCode == 0xFEFF &&
        records.isEmpty &&
        record.isEmpty &&
        field.isEmpty) {
      continue;
    }

    if (charCode == 34) {
      if (inQuotes && i + 1 < text.length && text.codeUnitAt(i + 1) == 34) {
        field.writeCharCode(34);
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (charCode == separatorCode && !inQuotes) {
      record.add(field.toString());
      field.clear();
    } else if (!inQuotes && (charCode == 10 || charCode == 13)) {
      record.add(field.toString());
      field.clear();

      if (record.any((cell) => cell.trim().isNotEmpty)) {
        records.add(List<String>.from(record));
      }

      record = <String>[];

      if (charCode == 13 &&
          i + 1 < text.length &&
          text.codeUnitAt(i + 1) == 10) {
        i++;
      }
    } else {
      field.writeCharCode(charCode);
    }
  }

  record.add(field.toString());

  if (record.any((cell) => cell.trim().isNotEmpty)) {
    records.add(List<String>.from(record));
  }

  return records;
}

String normalizzaChiave(String value) {
  var testo = value.trim().toUpperCase();

  const sostituzioni = <String, String>{
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ä': 'A',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Ö': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    '’': ' ',
    '`': ' ',
    '´': ' ',
    "'": ' ',
    '-': ' ',
    '‐': ' ',
    '–': ' ',
    '—': ' ',
    '.': ' ',
    ',': ' ',
  };

  for (final sostituzione in sostituzioni.entries) {
    testo = testo.replaceAll(sostituzione.key, sostituzione.value);
  }

  return testo.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String dartString(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}
