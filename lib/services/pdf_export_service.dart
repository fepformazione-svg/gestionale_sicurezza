import 'dart:io';

import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/pdf_azienda_helper.dart';

class PdfExportService {
  static Future<void> esportaTabella({
    required String titolo,
    required List<String> intestazioni,
    required List<List<String>> righe,
  }) async {
    final pdf = pw.Document();

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();
    final dataExport = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          intestazioneAziendaPdfWidget(intestazioneAzienda),
          pw.SizedBox(height: 6),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              dataExport,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey600,
              ),
            ),
          ),

          pw.SizedBox(height: 18),

          pw.Text(
            titolo,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 15),

          pw.TableHelper.fromTextArray(
            headers: intestazioni,
            data: righe,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder.all(color: PdfColors.grey500),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/${titolo.replaceAll(' ', '_')}.pdf');

    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);
  }
}
