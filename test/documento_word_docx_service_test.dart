import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:gestionale_sicurezza/services/documento_word_docx_service.dart';

void main() {
  group('DOC004 DocumentoWordDocxService', () {
    test(
      'genera una copia DOCX sostituendo placeholder normali e spezzati senza modificare il master',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'gestionale_sicurezza_doc004_docx_',
        );

        try {
          final master = File(
            '${tempDir.path}${Platform.pathSeparator}master.docx',
          );

          final output = File(
            '${tempDir.path}${Platform.pathSeparator}generato.docx',
          );

          await _creaDocxSintetico(master);

          final hashMasterPrima = sha256
              .convert(await master.readAsBytes())
              .toString();

          final service = DocumentoWordDocxService();

          final risultato = await service.generaDaModello(
            modelloPath: master.path,
            destinazionePath: output.path,
            placeholderValues: const {
              '{{NOME}}': 'Mario',
              '{{CODICE_FISCALE}}': 'RSSMRA80A01H501U',
              '{{IMPRESA}}': 'F&P S.r.l.s.',
            },
          );

          expect(risultato, output.path);

          expect(
            output.existsSync(),
            isTrue,
            reason: 'Deve essere creata una nuova copia DOCX.',
          );

          expect(output.absolute.path, isNot(master.absolute.path));

          final hashMasterDopo = sha256
              .convert(await master.readAsBytes())
              .toString();

          expect(
            hashMasterDopo,
            hashMasterPrima,
            reason:
                'Il modello Word master deve restare byte-per-byte invariato.',
          );

          final archivioGenerato = ZipDecoder().decodeBytes(
            await output.readAsBytes(),
          );

          final documentoXml = archivioGenerato.files.firstWhere(
            (file) => file.name == 'word/document.xml',
          );

          final xmlDocumento = utf8.decode(documentoXml.content as List<int>);

          final documento = XmlDocument.parse(xmlDocumento);

          final testoCompleto = documento.descendantElements
              .where((elemento) => elemento.name.local == 't')
              .map((elemento) => elemento.innerText)
              .join();

          expect(testoCompleto, contains('Nome: Mario'));

          expect(
            testoCompleto,
            contains('CF: RSSMRA80A01H501U'),
            reason:
                'Il placeholder deve essere sostituito anche quando Word lo divide tra più run.',
          );

          expect(
            testoCompleto,
            contains('Impresa: F&P S.r.l.s.'),
            reason: 'I caratteri speciali devono restare testo XML valido.',
          );

          expect(testoCompleto, contains('TESTO IMMUTATO'));

          expect(xmlDocumento, isNot(contains('{{NOME}}')));

          expect(xmlDocumento, isNot(contains('{{CODICE_FISCALE}}')));

          expect(xmlDocumento, isNot(contains('{{IMPRESA}}')));

          expect(
            xmlDocumento,
            contains('F&amp;P S.r.l.s.'),
            reason:
                'Il valore con & deve essere serializzato correttamente in XML.',
          );
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
    );

    test('rifiuta di usare il master stesso come destinazione', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'gestionale_sicurezza_doc004_master_guard_',
      );

      try {
        final master = File(
          '${tempDir.path}${Platform.pathSeparator}master.docx',
        );

        await _creaDocxSintetico(master);

        final hashPrima = sha256.convert(await master.readAsBytes()).toString();

        final service = DocumentoWordDocxService();

        await expectLater(
          () => service.generaDaModello(
            modelloPath: master.path,
            destinazionePath: master.path,
            placeholderValues: const {'{{NOME}}': 'Mario'},
          ),
          throwsA(isA<ArgumentError>()),
        );

        final hashDopo = sha256.convert(await master.readAsBytes()).toString();

        expect(
          hashDopo,
          hashPrima,
          reason:
              'Anche in caso di destinazione non valida il master non deve essere modificato.',
        );
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}

Future<void> _creaDocxSintetico(File file) async {
  final archive = Archive();

  archive.addFile(
    ArchiveFile.string('[Content_Types].xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
'''),
  );

  archive.addFile(
    ArchiveFile.string('_rels/.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship
    Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"
  />
</Relationships>
'''),
  );

  archive.addFile(
    ArchiveFile.string('word/document.xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
>
  <w:body>
    <w:p>
      <w:r>
        <w:t>Nome: </w:t>
      </w:r>
      <w:r>
        <w:t>{{NOME}}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:r>
        <w:t>CF: </w:t>
      </w:r>
      <w:r>
        <w:t>{{CODICE_</w:t>
      </w:r>
      <w:r>
        <w:t>FISCALE}}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:r>
        <w:t>Impresa: {{IMPRESA}}</w:t>
      </w:r>
    </w:p>

    <w:p>
      <w:r>
        <w:t>TESTO IMMUTATO</w:t>
      </w:r>
    </w:p>

    <w:sectPr>
      <w:pgSz
        w:w="11906"
        w:h="16838"
      />
    </w:sectPr>
  </w:body>
</w:document>
'''),
  );

  final bytes = ZipEncoder().encode(archive);

  if (bytes == null) {
    throw StateError('Impossibile codificare il DOCX sintetico.');
  }

  await file.writeAsBytes(bytes, flush: true);
}
