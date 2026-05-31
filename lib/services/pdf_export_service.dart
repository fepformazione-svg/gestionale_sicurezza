import 'dart:io';

import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  static Future<void> esportaTabella({
    required String titolo,
    required List<String> intestazioni,
    required List<List<String>> righe,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),

        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GESTIONALE SICUREZZA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
            ],
          ),

          pw.SizedBox(height: 20),

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
