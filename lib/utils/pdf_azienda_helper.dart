import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/app_database.dart';

class IntestazioneAziendaPdf {
  final String titolo;
  final String sottotitolo;
  final String dettaglio;

  const IntestazioneAziendaPdf({
    required this.titolo,
    required this.sottotitolo,
    required this.dettaglio,
  });
}

String _testoPulito(dynamic valore) {
  return valore?.toString().trim() ?? '';
}

String _unisciParti(List<String> parti, {String separatore = ' - '}) {
  return parti.where((parte) => parte.trim().isNotEmpty).join(separatore);
}

Future<IntestazioneAziendaPdf> caricaIntestazioneAziendaPdf() async {
  final dati = await AppDatabase.instance.getDatiAzienda();

  if (dati == null) {
    return const IntestazioneAziendaPdf(
      titolo: 'F&P Formazione e Prevenzione',
      sottotitolo: '',
      dettaglio: '',
    );
  }

  final ragioneSociale = _testoPulito(dati['ragione_sociale']);
  final nomeCommerciale = _testoPulito(dati['nome_commerciale']);
  final partitaIva = _testoPulito(dati['partita_iva']);
  final codiceFiscale = _testoPulito(dati['codice_fiscale']);
  final indirizzo = _testoPulito(dati['indirizzo']);
  final cap = _testoPulito(dati['cap']);
  final comune = _testoPulito(dati['comune']);
  final provincia = _testoPulito(dati['provincia']);
  final telefono = _testoPulito(dati['telefono']);
  final email = _testoPulito(dati['email']);
  final pec = _testoPulito(dati['pec']);
  final sitoWeb = _testoPulito(dati['sito_web']);

  final titolo = nomeCommerciale.isNotEmpty
      ? nomeCommerciale
      : ragioneSociale.isNotEmpty
      ? ragioneSociale
      : 'F&P Formazione e Prevenzione';

  final sede = _unisciParti([
    indirizzo,
    _unisciParti([cap, comune, provincia], separatore: ' '),
  ]);

  final datiFiscali = _unisciParti([
    if (partitaIva.isNotEmpty) 'P.IVA $partitaIva',
    if (codiceFiscale.isNotEmpty) 'CF $codiceFiscale',
  ]);

  final contatti = _unisciParti([
    if (telefono.isNotEmpty) 'Tel. $telefono',
    if (email.isNotEmpty) email,
    if (pec.isNotEmpty) 'PEC $pec',
    if (sitoWeb.isNotEmpty) sitoWeb,
  ]);

  return IntestazioneAziendaPdf(
    titolo: titolo,
    sottotitolo: _unisciParti([ragioneSociale, datiFiscali]),
    dettaglio: _unisciParti([sede, contatti]),
  );
}

pw.Widget intestazioneAziendaPdfWidget(IntestazioneAziendaPdf intestazione) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        intestazione.titolo,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
      if (intestazione.sottotitolo.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        pw.Text(
          intestazione.sottotitolo,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700),
        ),
      ],
      if (intestazione.dettaglio.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          intestazione.dettaglio,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey600),
        ),
      ],
    ],
  );
}
