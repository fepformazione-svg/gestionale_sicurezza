import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

class DocumentoWordDocxService {
  Future<String> generaDaModello({
    required String modelloPath,
    required String destinazionePath,
    required Map<String, String> placeholderValues,
  }) async {
    final modelloPulito = modelloPath.trim();
    final destinazionePulita = destinazionePath.trim();

    if (modelloPulito.isEmpty) {
      throw ArgumentError.value(
        modelloPath,
        'modelloPath',
        'Il percorso del modello Word non può essere vuoto.',
      );
    }

    if (destinazionePulita.isEmpty) {
      throw ArgumentError.value(
        destinazionePath,
        'destinazionePath',
        'Il percorso di destinazione non può essere vuoto.',
      );
    }

    if (_stessoPercorso(modelloPulito, destinazionePulita)) {
      throw ArgumentError(
        'Il file di destinazione deve essere diverso dal modello Word master.',
      );
    }

    final modello = File(modelloPulito);

    if (!await modello.exists()) {
      throw FileSystemException('Modello Word non trovato.', modelloPulito);
    }

    final destinazione = File(destinazionePulita);

    if (await destinazione.exists()) {
      throw FileSystemException(
        'Il file di destinazione esiste già.',
        destinazionePulita,
      );
    }

    final modelloBytes = await modello.readAsBytes();

    final archivioMaster = ZipDecoder().decodeBytes(modelloBytes);

    final contieneDocumentoPrincipale = archivioMaster.files.any(
      (file) => file.isFile && file.name == 'word/document.xml',
    );

    if (!contieneDocumentoPrincipale) {
      throw StateError('Il file selezionato non contiene word/document.xml.');
    }

    final archivioGenerato = Archive();

    for (final file in archivioMaster.files) {
      if (!file.isFile) {
        continue;
      }

      final contenutoOriginale = List<int>.from(file.content as List<int>);

      final contenutoGenerato = _isParteTestualeWord(file.name)
          ? _sostituisciPlaceholderXml(contenutoOriginale, placeholderValues)
          : contenutoOriginale;

      archivioGenerato.addFile(
        ArchiveFile(file.name, contenutoGenerato.length, contenutoGenerato),
      );
    }

    final docxBytes = ZipEncoder().encode(archivioGenerato);

    if (docxBytes == null) {
      throw StateError('Impossibile codificare il documento Word generato.');
    }

    await destinazione.parent.create(recursive: true);

    await destinazione.writeAsBytes(docxBytes, flush: true);

    return destinazione.path;
  }

  bool _stessoPercorso(String primo, String secondo) {
    var primoNormalizzato = p.normalize(p.absolute(primo));

    var secondoNormalizzato = p.normalize(p.absolute(secondo));

    if (Platform.isWindows) {
      primoNormalizzato = primoNormalizzato.toLowerCase();
      secondoNormalizzato = secondoNormalizzato.toLowerCase();
    }

    return primoNormalizzato == secondoNormalizzato;
  }

  bool _isParteTestualeWord(String nome) {
    final normalizzato = nome.toLowerCase();

    if (normalizzato == 'word/document.xml' ||
        normalizzato == 'word/footnotes.xml' ||
        normalizzato == 'word/endnotes.xml' ||
        normalizzato == 'word/comments.xml') {
      return true;
    }

    if (RegExp(r'^word/header\d+\.xml$').hasMatch(normalizzato)) {
      return true;
    }

    if (RegExp(r'^word/footer\d+\.xml$').hasMatch(normalizzato)) {
      return true;
    }

    return false;
  }

  List<int> _sostituisciPlaceholderXml(
    List<int> bytes,
    Map<String, String> placeholderValues,
  ) {
    final xmlOriginale = utf8.decode(bytes, allowMalformed: false);

    final documento = XmlDocument.parse(xmlOriginale.trim());

    final paragrafi = documento.descendantElements
        .where((elemento) => elemento.name.local == 'p')
        .toList(growable: false);

    for (final paragrafo in paragrafi) {
      final elementiTesto = paragrafo.descendantElements
          .where((elemento) => elemento.name.local == 't')
          .toList(growable: false);

      if (elementiTesto.isEmpty) {
        continue;
      }

      for (final entry in placeholderValues.entries) {
        final placeholder = entry.key;

        if (placeholder.isEmpty) {
          continue;
        }

        _sostituisciPlaceholderNelParagrafo(
          elementiTesto,
          placeholder,
          entry.value,
        );
      }
    }

    return utf8.encode(documento.toXmlString(pretty: false));
  }

  void _sostituisciPlaceholderNelParagrafo(
    List<XmlElement> elementiTesto,
    String placeholder,
    String valore,
  ) {
    final testoParagrafo = elementiTesto
        .map((elemento) => elemento.innerText)
        .join();

    if (!testoParagrafo.contains(placeholder)) {
      return;
    }

    final occorrenze = <int>[];

    var daIndice = 0;

    while (true) {
      final indice = testoParagrafo.indexOf(placeholder, daIndice);

      if (indice < 0) {
        break;
      }

      occorrenze.add(indice);

      daIndice = indice + placeholder.length;
    }

    for (final indice in occorrenze.reversed) {
      _sostituisciIntervallo(
        elementiTesto,
        indice,
        indice + placeholder.length,
        valore,
      );
    }
  }

  void _sostituisciIntervallo(
    List<XmlElement> elementiTesto,
    int inizio,
    int fine,
    String valore,
  ) {
    int? indiceElementoInizio;
    int? indiceElementoFine;

    var offsetInizio = 0;
    var offsetFine = 0;
    var cursore = 0;

    for (var i = 0; i < elementiTesto.length; i++) {
      final testo = elementiTesto[i].innerText;
      final prossimoCursore = cursore + testo.length;

      if (indiceElementoInizio == null &&
          inizio >= cursore &&
          inizio < prossimoCursore) {
        indiceElementoInizio = i;
        offsetInizio = inizio - cursore;
      }

      if (indiceElementoInizio != null &&
          fine > cursore &&
          fine <= prossimoCursore) {
        indiceElementoFine = i;
        offsetFine = fine - cursore;
        break;
      }

      cursore = prossimoCursore;
    }

    if (indiceElementoInizio == null || indiceElementoFine == null) {
      throw StateError('Impossibile localizzare il placeholder nei nodi Word.');
    }

    final elementoInizio = elementiTesto[indiceElementoInizio];

    final testoInizio = elementoInizio.innerText;

    if (indiceElementoInizio == indiceElementoFine) {
      elementoInizio.innerText =
          testoInizio.substring(0, offsetInizio) +
          valore +
          testoInizio.substring(offsetFine);

      return;
    }

    final elementoFine = elementiTesto[indiceElementoFine];

    final testoFine = elementoFine.innerText;

    elementoInizio.innerText = testoInizio.substring(0, offsetInizio) + valore;

    for (var i = indiceElementoInizio + 1; i < indiceElementoFine; i++) {
      elementiTesto[i].innerText = '';
    }

    elementoFine.innerText = testoFine.substring(offsetFine);
  }
}
