import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

import '../utils/pdf_azienda_helper.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import '../services/codice_catastale_service.dart';
import '../services/codice_fiscale_service.dart';
import '../services/pdf_export_service.dart';

import '../widgets/app_search_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../widgets/data_text_input_formatter.dart';

import 'discente_scheda_page.dart';

const double discenteRowHeight = 48;

const double colNome = 220;
const double colCognome = 240;
const double colLuogoNascita = 230;
const double colDataNascita = 150;
const double colCodiceFiscale = 250;
const double colImpresa = 300;
const double colAzioni = 130;

const double discentiTableWidth =
    colNome +
    colCognome +
    colLuogoNascita +
    colDataNascita +
    colCodiceFiscale +
    colImpresa +
    colAzioni;

bool _dataNascitaValida(String valore) {
  final testo = valore.trim();

  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(testo);
  if (match == null) {
    return false;
  }

  final giorno = int.tryParse(match.group(1)!);
  final mese = int.tryParse(match.group(2)!);
  final anno = int.tryParse(match.group(3)!);

  if (giorno == null || mese == null || anno == null) {
    return false;
  }

  final oggi = DateTime.now();
  if (anno < 1900 || anno > oggi.year) {
    return false;
  }

  final data = DateTime(anno, mese, giorno);

  final componentiCoerenti =
      data.day == giorno && data.month == mese && data.year == anno;

  if (!componentiCoerenti) {
    return false;
  }

  final oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);
  final dataSoloData = DateTime(data.year, data.month, data.day);

  return !dataSoloData.isAfter(oggiSoloData);
}

class DiscentiPage extends StatefulWidget {
  final String globalSearch;

  const DiscentiPage({super.key, this.globalSearch = ''});

  @override
  State<DiscentiPage> createState() => _DiscentiPageState();
}

class _DiscentiPageState extends State<DiscentiPage> {
  List<Discente> discenti = [];
  List<Discente> discentiFiltrati = [];
  List<Impresa> imprese = [];

  bool loading = true;
  int? sortColumnIndex;
  bool sortAscending = false;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  int? discenteSelezionatoId;

  String colonnaOrdinata = '';
  bool ordineCrescente = true;

  @override
  void initState() {
    super.initState();
    caricaDati();
  }

  @override
  void didUpdateWidget(covariant DiscentiPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.globalSearch != widget.globalSearch) {
      cercaDiscenti(widget.globalSearch);
    }
  }

  Future<void> caricaDati() async {
    final datiDiscenti = await DatabaseService.instance.getDiscenti();
    final datiImprese = await DatabaseService.instance.getImprese();

    if (!mounted) return;

    setState(() {
      discenti = datiDiscenti;
      discentiFiltrati = datiDiscenti;
      imprese = datiImprese;
      loading = false;
    });

    if (widget.globalSearch.trim().isNotEmpty) {
      cercaDiscenti(widget.globalSearch);
    }
  }

  void cercaDiscenti(String valore) {
    final query = valore.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        discentiFiltrati = discenti;
        return;
      }

      discentiFiltrati = discenti.where((d) {
        final nome = d.nome.toLowerCase();
        final cognome = d.cognome.toLowerCase();
        final nominativo = d.nominativoCompleto.toLowerCase();
        final luogo = (d.luogoNascita ?? '').toLowerCase();
        final data = (d.dataNascita ?? '').toLowerCase();
        final codiceFiscale = (d.codiceFiscale ?? '').toLowerCase();
        final impresa = (d.nomeImpresa ?? '').toLowerCase();

        return nome.contains(query) ||
            cognome.contains(query) ||
            nominativo.contains(query) ||
            luogo.contains(query) ||
            data.contains(query) ||
            codiceFiscale.contains(query) ||
            impresa.contains(query);
      }).toList();
    });
  }

  void ordinaNominativo(int columnIndex, bool ascending) {
    discentiFiltrati.sort((a, b) {
      final nominativoA = a.nominativoCompleto.toLowerCase();
      final nominativoB = b.nominativoCompleto.toLowerCase();

      final result = nominativoA.compareTo(nominativoB);

      return ascending ? result : -result;
    });

    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  String? _sessoDaCodiceFiscale(String? codiceFiscale) {
    final cf = codiceFiscale?.trim().toUpperCase() ?? '';

    if (cf.length != 16) {
      return null;
    }

    final giorno = int.tryParse(cf.substring(9, 11));

    if (giorno == null) {
      return null;
    }

    if (giorno > 40) {
      return 'F';
    }

    return 'M';
  }

  String? _meseCodiceFiscaleDaNumero(int mese) {
    const mesi = {
      1: 'A',
      2: 'B',
      3: 'C',
      4: 'D',
      5: 'E',
      6: 'H',
      7: 'L',
      8: 'M',
      9: 'P',
      10: 'R',
      11: 'S',
      12: 'T',
    };

    return mesi[mese];
  }

  bool _codiceFiscaleCoerenteConSesso(String codiceFiscale, String? sesso) {
    if (sesso != 'M' && sesso != 'F') {
      return true;
    }

    final sessoDaCodiceFiscale = _sessoDaCodiceFiscale(codiceFiscale);

    return sessoDaCodiceFiscale == null || sessoDaCodiceFiscale == sesso;
  }

  bool _codiceFiscaleCoerenteConDataNascita(
    String codiceFiscale,
    String dataNascita,
  ) {
    final cf = codiceFiscale.trim().toUpperCase();
    final data = dataNascita.trim();

    if (cf.length != 16 || !_dataNascitaValida(data)) {
      return false;
    }

    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(data);
    if (match == null) {
      return false;
    }

    final giorno = int.tryParse(match.group(1)!);
    final mese = int.tryParse(match.group(2)!);
    final anno = match.group(3)!;

    if (giorno == null || mese == null) {
      return false;
    }

    final annoCodiceFiscale = cf.substring(6, 8);
    final meseCodiceFiscale = cf.substring(8, 9);
    final giornoCodiceFiscale = int.tryParse(cf.substring(9, 11));
    final meseAtteso = _meseCodiceFiscaleDaNumero(mese);

    if (giornoCodiceFiscale == null || meseAtteso == null) {
      return false;
    }

    final giornoMaschile = giorno;
    final giornoFemminile = giorno + 40;

    return annoCodiceFiscale == anno.substring(2, 4) &&
        meseCodiceFiscale == meseAtteso &&
        (giornoCodiceFiscale == giornoMaschile ||
            giornoCodiceFiscale == giornoFemminile);
  }

  bool _codiceFiscaleManualeValido(String codiceFiscale) {
    final cf = codiceFiscale.trim().toUpperCase();

    return RegExp(
      r'^[A-Z]{6}[0-9]{2}[A-Z][0-9]{2}[A-Z][0-9]{3}[A-Z]$',
    ).hasMatch(cf);
  }

  bool _carattereControlloCodiceFiscaleValido(String codiceFiscale) {
    final cf = codiceFiscale.trim().toUpperCase();

    if (cf.length != 16) {
      return false;
    }

    const valoriPari = <String, int>{
      '0': 0,
      '1': 1,
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      'A': 0,
      'B': 1,
      'C': 2,
      'D': 3,
      'E': 4,
      'F': 5,
      'G': 6,
      'H': 7,
      'I': 8,
      'J': 9,
      'K': 10,
      'L': 11,
      'M': 12,
      'N': 13,
      'O': 14,
      'P': 15,
      'Q': 16,
      'R': 17,
      'S': 18,
      'T': 19,
      'U': 20,
      'V': 21,
      'W': 22,
      'X': 23,
      'Y': 24,
      'Z': 25,
    };

    const valoriDispari = <String, int>{
      '0': 1,
      '1': 0,
      '2': 5,
      '3': 7,
      '4': 9,
      '5': 13,
      '6': 15,
      '7': 17,
      '8': 19,
      '9': 21,
      'A': 1,
      'B': 0,
      'C': 5,
      'D': 7,
      'E': 9,
      'F': 13,
      'G': 15,
      'H': 17,
      'I': 19,
      'J': 21,
      'K': 2,
      'L': 4,
      'M': 18,
      'N': 20,
      'O': 11,
      'P': 3,
      'Q': 6,
      'R': 8,
      'S': 12,
      'T': 14,
      'U': 16,
      'V': 10,
      'W': 22,
      'X': 25,
      'Y': 24,
      'Z': 23,
    };

    const lettereControllo = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    var somma = 0;

    for (var i = 0; i < 15; i++) {
      final carattere = cf[i];
      final valore = i.isEven
          ? valoriDispari[carattere]
          : valoriPari[carattere];

      if (valore == null) {
        return false;
      }

      somma += valore;
    }

    final carattereAtteso = lettereControllo[somma % 26];
    return cf[15] == carattereAtteso;
  }

  Future<void> apriDialogDiscente({Discente? discente}) async {
    final nomeController = TextEditingController(text: discente?.nome ?? '');
    final cognomeController = TextEditingController(
      text: discente?.cognome ?? '',
    );
    final luogoController = TextEditingController(
      text: discente?.luogoNascita ?? '',
    );
    final dataController = TextEditingController(
      text: discente?.dataNascita ?? '',
    );
    final cfController = TextEditingController(
      text: discente?.codiceFiscale ?? '',
    );

    final dataVisitaController = TextEditingController(
      text: discente?.dataVisitaMedica ?? '',
    );

    final scadenzaVisitaController = TextEditingController(
      text: discente?.scadenzaVisitaMedica ?? '',
    );

    bool visitaMedicaSvolta = (discente?.visitaMedicaSvolta ?? 0) == 1;

    bool dataNascitaNonValida = false;

    String? sesso = discente?.sesso;
    if (sesso != 'M' && sesso != 'F') {
      sesso = _sessoDaCodiceFiscale(discente?.codiceFiscale);
    }

    int? impresaId = discente?.impresaId;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void ricalcolaCodiceFiscale() {
              final nome = nomeController.text.trim();
              final cognome = cognomeController.text.trim();
              final luogoNascita = luogoController.text.trim();
              final dataNascita = dataController.text.trim();

              if (nome.isEmpty ||
                  cognome.isEmpty ||
                  luogoNascita.isEmpty ||
                  dataNascita.isEmpty ||
                  sesso == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Per ricalcolare il codice fiscale compila nome, cognome, luogo di nascita, data di nascita e sesso.',
                    ),
                    backgroundColor: Color(0xFFF59E0B),
                  ),
                );
                return;
              }

              if (!_dataNascitaValida(dataNascita)) {
                setDialogState(() {
                  dataNascitaNonValida = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Data di nascita non valida. Inserire una data reale nel formato gg/mm/aaaa.',
                    ),
                    backgroundColor: Color(0xFFF59E0B),
                  ),
                );
                return;
              }

              setDialogState(() {
                dataNascitaNonValida = false;
              });

              final codiceCatastaleNascita =
                  CodiceCatastaleService.cercaCodiceCatastale(luogoNascita);

              if (codiceCatastaleNascita == null) {
                final messaggioComuneAmbiguo =
                    CodiceCatastaleService.messaggioComuneItalianoAmbiguo(
                      luogoNascita,
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      messaggioComuneAmbiguo ??
                          'Luogo/Nazione di nascita non riconosciuto. Correggi il luogo di nascita oppure inserisci il codice fiscale manualmente.',
                    ),
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                );
                return;
              }

              final codiceFiscaleCalcolato =
                  CodiceFiscaleService.generaCodiceFiscale(
                    cognome: cognome,
                    nome: nome,
                    dataNascita: dataNascita,
                    sesso: sesso,
                    codiceCatastaleNascita: codiceCatastaleNascita,
                  );

              if (codiceFiscaleCalcolato == null ||
                  codiceFiscaleCalcolato.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Codice fiscale non calcolabile. Verifica i dati anagrafici inseriti.',
                    ),
                    backgroundColor: Color(0xFFF59E0B),
                  ),
                );
                return;
              }

              setDialogState(() {
                cfController.text = codiceFiscaleCalcolato;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Codice fiscale ricalcolato automaticamente.'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Container(
                width: 720,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discente == null
                            ? 'Nuovo discente'
                            : 'Modifica discente',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Anagrafica completa del partecipante.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cognomeController,
                              decoration: _inputDecoration('Cognome *'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: nomeController,
                              decoration: _inputDecoration('Nome *'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: luogoController,
                              decoration: _inputDecoration('Luogo di nascita'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: dataController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [DataTextInputFormatter()],
                              decoration: _inputDecoration('Data nascita').copyWith(
                                helperText: dataNascitaNonValida
                                    ? 'Data non valida: usa gg/mm/aaaa e una data reale.'
                                    : 'Formato gg/mm/aaaa',
                                helperStyle: dataNascitaNonValida
                                    ? const TextStyle(color: Color(0xFFDC2626))
                                    : null,
                                suffixIcon: dataNascitaNonValida
                                    ? const Icon(
                                        Icons.error,
                                        color: Color(0xFFDC2626),
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  final testo = value.trim();
                                  dataNascitaNonValida =
                                      testo.isNotEmpty &&
                                      !_dataNascitaValida(testo);
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String?>(
                        initialValue: sesso,
                        decoration: _inputDecoration(
                          'Sesso per codice fiscale',
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Non specificato'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'M',
                            child: Text('Maschio'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'F',
                            child: Text('Femmina'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            sesso = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cfController,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(16),
                                TextInputFormatter.withFunction((
                                  oldValue,
                                  newValue,
                                ) {
                                  return newValue.copyWith(
                                    text: newValue.text.toUpperCase(),
                                    selection: newValue.selection,
                                  );
                                }),
                              ],
                              decoration: (() {
                                final codiceFiscaleInserito = cfController.text
                                    .trim()
                                    .toUpperCase();
                                final dataNascitaInserita = dataController.text
                                    .trim();

                                final codiceFiscaleCampoCompilato =
                                    codiceFiscaleInserito.isNotEmpty &&
                                    codiceFiscaleInserito != '-';

                                final codiceFiscaleValido =
                                    codiceFiscaleCampoCompilato &&
                                    _codiceFiscaleManualeValido(
                                      codiceFiscaleInserito,
                                    ) &&
                                    _carattereControlloCodiceFiscaleValido(
                                      codiceFiscaleInserito,
                                    );

                                final sessoCoerenteConCodiceFiscale =
                                    !codiceFiscaleValido ||
                                    _codiceFiscaleCoerenteConSesso(
                                      codiceFiscaleInserito,
                                      sesso,
                                    );

                                final dataCoerenteConCodiceFiscale =
                                    !codiceFiscaleValido ||
                                    dataNascitaInserita.isEmpty ||
                                    !_dataNascitaValida(dataNascitaInserita) ||
                                    _codiceFiscaleCoerenteConDataNascita(
                                      codiceFiscaleInserito,
                                      dataNascitaInserita,
                                    );

                                final codiceFiscaleCoerente =
                                    codiceFiscaleValido &&
                                    sessoCoerenteConCodiceFiscale &&
                                    dataCoerenteConCodiceFiscale;

                                String helperText;
                                if (!codiceFiscaleCampoCompilato) {
                                  helperText =
                                      'Automatico dai dati anagrafici. Puoi modificarlo o ricalcolarlo.';
                                } else if (!codiceFiscaleValido) {
                                  helperText =
                                      'Manuale non valido: controlla formato e carattere finale.';
                                } else if (!sessoCoerenteConCodiceFiscale) {
                                  helperText =
                                      'Manuale non coerente: il sesso ricavato dal codice fiscale non coincide.';
                                } else if (!dataCoerenteConCodiceFiscale) {
                                  helperText =
                                      'Manuale non coerente: la data di nascita non coincide.';
                                } else {
                                  helperText =
                                      'Manuale valido: formato, controllo, sesso e data verificati.';
                                }

                                return _inputDecoration(
                                  codiceFiscaleCampoCompilato
                                      ? 'Codice fiscale presente/manuale'
                                      : 'Codice fiscale automatico',
                                ).copyWith(
                                  helperText: helperText,
                                  helperStyle: codiceFiscaleCampoCompilato
                                      ? TextStyle(
                                          color: codiceFiscaleCoerente
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFDC2626),
                                        )
                                      : null,
                                  suffixIcon: codiceFiscaleCampoCompilato
                                      ? Icon(
                                          codiceFiscaleCoerente
                                              ? Icons.check_circle
                                              : Icons.error,
                                          color: codiceFiscaleCoerente
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFDC2626),
                                        )
                                      : null,
                                );
                              })(),
                              onChanged: (_) {
                                final codiceFiscaleInserito = cfController.text
                                    .trim()
                                    .toUpperCase();

                                final sessoDaCodiceFiscale =
                                    _sessoDaCodiceFiscale(
                                      codiceFiscaleInserito,
                                    );

                                setDialogState(() {
                                  if (_codiceFiscaleManualeValido(
                                        codiceFiscaleInserito,
                                      ) &&
                                      _carattereControlloCodiceFiscaleValido(
                                        codiceFiscaleInserito,
                                      ) &&
                                      sessoDaCodiceFiscale != null) {
                                    sesso = sessoDaCodiceFiscale;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: OutlinedButton.icon(
                              onPressed: ricalcolaCodiceFiscale,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Ricalcola'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<int?>(
                        initialValue: impresaId,
                        decoration: _inputDecoration('Impresa di appartenenza'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Nessuna impresa'),
                          ),
                          ...imprese.map(
                            (impresa) => DropdownMenuItem<int?>(
                              value: impresa.id,
                              child: Text(impresa.nome),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            impresaId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      CheckboxListTile(
                        value: visitaMedicaSvolta,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visita medica svolta'),
                        onChanged: (value) {
                          setDialogState(() {
                            visitaMedicaSvolta = value ?? false;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dataVisitaController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [DataTextInputFormatter()],
                              decoration: _inputDecoration(
                                'Data visita',
                              ).copyWith(helperText: 'Formato gg/mm/aaaa'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: scadenzaVisitaController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [DataTextInputFormatter()],
                              decoration: _inputDecoration(
                                'Scadenza visita',
                              ).copyWith(helperText: 'Formato gg/mm/aaaa'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final nome = nomeController.text.trim();
                              final cognome = cognomeController.text.trim();
                              final luogoNascita = luogoController.text.trim();
                              final dataNascita = dataController.text.trim();

                              if (nome.isEmpty || cognome.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nome e cognome sono obbligatori',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (!_dataNascitaValida(dataNascita)) {
                                setDialogState(() {
                                  dataNascitaNonValida = true;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Data di nascita non valida. Correggere il formato gg/mm/aaaa prima di salvare.',
                                    ),
                                    backgroundColor: Color(0xFFF59E0B),
                                  ),
                                );
                                return;
                              }

                              setDialogState(() {
                                dataNascitaNonValida = false;
                              });

                              final codiceCatastaleNascita =
                                  CodiceCatastaleService.cercaCodiceCatastale(
                                    luogoNascita,
                                  );

                              if (luogoNascita.isNotEmpty &&
                                  codiceCatastaleNascita == null &&
                                  cfController.text.trim().isEmpty) {
                                final messaggioComuneAmbiguo =
                                    CodiceCatastaleService.messaggioComuneItalianoAmbiguo(
                                      luogoNascita,
                                    );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      messaggioComuneAmbiguo ??
                                          'Luogo/Nazione di nascita non riconosciuto. Inserisci il codice fiscale manualmente oppure correggi il luogo di nascita.',
                                    ),
                                    backgroundColor: const Color(0xFFF59E0B),
                                  ),
                                );
                                return;
                              }

                              final codiceFiscaleCalcolato =
                                  CodiceFiscaleService.generaCodiceFiscale(
                                    cognome: cognome,
                                    nome: nome,
                                    dataNascita: dataNascita,
                                    sesso: sesso,
                                    codiceCatastaleNascita:
                                        codiceCatastaleNascita,
                                  );

                              final codiceFiscaleInserito = cfController.text
                                  .trim()
                                  .toUpperCase();
                              final codiceFiscaleCampoCompilato =
                                  codiceFiscaleInserito.isNotEmpty &&
                                  codiceFiscaleInserito != '-';
                              if (codiceFiscaleCampoCompilato &&
                                  !_codiceFiscaleManualeValido(
                                    codiceFiscaleInserito,
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Codice fiscale non valido. Inserisci 16 caratteri nel formato corretto, es. RSSMRA80C12H501E.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }
                              if (codiceFiscaleCampoCompilato &&
                                  !_carattereControlloCodiceFiscaleValido(
                                    codiceFiscaleInserito,
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Codice fiscale non valido: il carattere finale di controllo non è coerente.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              if (codiceFiscaleCampoCompilato &&
                                  !_codiceFiscaleCoerenteConSesso(
                                    codiceFiscaleInserito,
                                    sesso,
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Codice fiscale non coerente: il sesso ricavato dal codice fiscale non coincide con quello selezionato.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              if (codiceFiscaleCampoCompilato &&
                                  !_codiceFiscaleCoerenteConDataNascita(
                                    codiceFiscaleInserito,
                                    dataNascita,
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Codice fiscale non coerente: la data di nascita non coincide con quella inserita.',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              final nuovoDiscente = Discente(
                                id: discente?.id,
                                nome: nome,
                                cognome: cognome,
                                luogoNascita: luogoNascita,
                                dataNascita: dataNascita,
                                sesso: sesso,
                                codiceCatastaleNascita: codiceCatastaleNascita,
                                codiceFiscale: codiceFiscaleCampoCompilato
                                    ? codiceFiscaleInserito
                                    : codiceFiscaleCalcolato ?? '',
                                impresaId: impresaId,

                                visitaMedicaSvolta: visitaMedicaSvolta ? 1 : 0,
                                dataVisitaMedica: dataVisitaController.text
                                    .trim(),
                                scadenzaVisitaMedica: scadenzaVisitaController
                                    .text
                                    .trim(),
                              );

                              if (discente == null) {
                                await DatabaseService.instance.insertDiscente(
                                  nuovoDiscente,
                                );
                              } else {
                                await DatabaseService.instance.updateDiscente(
                                  nuovoDiscente,
                                );
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Salva'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nomeController.dispose();
    cognomeController.dispose();
    luogoController.dispose();
    dataController.dispose();
    cfController.dispose();
    dataVisitaController.dispose();
    scadenzaVisitaController.dispose();

    if (salvato == true) {
      if (!mounted) return;
      await caricaDati();
    }
  }

  Future<void> eliminaDiscente(Discente discente) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Elimina discente'),
          content: Text('Vuoi eliminare ${discente.nominativoCompleto}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );

    if (conferma != true || discente.id == null) return;

    await DatabaseService.instance.deleteDiscente(discente.id!);
    await caricaDati();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  String testoVuoto(String? valore) {
    if (valore == null || valore.trim().isEmpty) return '-';
    return valore.trim();
  }

  Future<void> esportaExcelDiscenti() async {
    final righe = discentiFiltrati;

    if (righe.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun discente da esportare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );

      return;
    }

    final excel = xls.Excel.createExcel();
    final sheet = excel['Discenti'];

    excel.delete('Sheet1');

    final adesso = DateTime.now();

    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata = discentiFiltrati.length != discenti.length;

    sheet.appendRow([
      xls.TextCellValue(
        vistaFiltrata
            ? 'Export discenti filtrato - ${righe.length} record - $dataExport'
            : 'Export discenti completo - ${righe.length} record - $dataExport',
      ),
    ]);

    final intestazioni = [
      'Nome',
      'Cognome',
      'Luogo nascita',
      'Data nascita',
      'Codice fiscale',
      'Impresa',
    ];

    sheet.appendRow(
      intestazioni.map((testo) => xls.TextCellValue(testo)).toList(),
    );

    for (var colonna = 0; colonna < intestazioni.length; colonna++) {
      sheet
          .cell(
            xls.CellIndex.indexByColumnRow(columnIndex: colonna, rowIndex: 1),
          )
          .cellStyle = xls.CellStyle(
        bold: true,
      );
    }

    for (final discente in righe) {
      sheet.appendRow([
        xls.TextCellValue(testoVuoto(discente.nome)),
        xls.TextCellValue(testoVuoto(discente.cognome)),
        xls.TextCellValue(testoVuoto(discente.luogoNascita)),
        xls.TextCellValue(testoVuoto(discente.dataNascita)),
        xls.TextCellValue(testoVuoto(discente.codiceFiscale)),
        xls.TextCellValue(testoVuoto(discente.nomeImpresa)),
      ]);
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 26);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 24);
    sheet.setColumnWidth(5, 34);

    final timestamp =
        '${adesso.year}_'
        '${adesso.month.toString().padLeft(2, '0')}_'
        '${adesso.day.toString().padLeft(2, '0')}_'
        '${adesso.hour.toString().padLeft(2, '0')}h'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final nomeFile = vistaFiltrata
        ? 'discenti_export_filtrato_$timestamp.xlsx'
        : 'discenti_export_$timestamp.xlsx';

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$nomeFile');

    final bytes = excel.encode();

    if (bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante la creazione del file Excel'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vistaFiltrata
              ? 'Export Excel completato: ${righe.length} discenti esportati dalla vista filtrata'
              : 'Export Excel completato: ${righe.length} discenti esportati',
        ),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  Future<void> stampaDiscenti() async {
    final righe = discentiFiltrati;

    if (righe.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun discente da stampare'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );

      return;
    }

    final adesso = DateTime.now();

    final dataExport =
        '${adesso.day.toString().padLeft(2, '0')}/'
        '${adesso.month.toString().padLeft(2, '0')}/'
        '${adesso.year} '
        '${adesso.hour.toString().padLeft(2, '0')}:'
        '${adesso.minute.toString().padLeft(2, '0')}';

    final vistaFiltrata = discentiFiltrati.length != discenti.length;

    final intestazioneAzienda = await caricaIntestazioneAziendaPdf();

    await Printing.layoutPdf(
      name: 'discenti_stampa',
      format: PdfPageFormat.a4.landscape,
      onLayout: (format) async {
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(24),
            footer: (context) {
              return pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Pagina ${context.pageNumber} di ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              );
            },
            build: (context) {
              return [
                intestazioneAziendaPdfWidget(intestazioneAzienda),
                pw.SizedBox(height: 8),
                pw.Text(
                  'DISCENTI',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  vistaFiltrata
                      ? 'Stampa discenti filtrata - ${righe.length} record - $dataExport'
                      : 'Stampa discenti completa - ${righe.length} record - $dataExport',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blueGrey700,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: const [
                    'Nome',
                    'Cognome',
                    'Luogo nascita',
                    'Data nascita',
                    'Codice fiscale',
                    'Impresa',
                  ],
                  data: righe.map((d) {
                    return [
                      testoVuoto(d.nome),
                      testoVuoto(d.cognome),
                      testoVuoto(d.luogoNascita),
                      testoVuoto(d.dataNascita),
                      testoVuoto(d.codiceFiscale),
                      testoVuoto(d.nomeImpresa),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.centerLeft,
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.blueGrey100,
                        width: 0.5,
                      ),
                    ),
                  ),
                  oddRowDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.4),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                  },
                ),
              ];
            },
          ),
        );

        return pdf.save();
      },
    );
  }

  void ordinaDiscenti(String colonna) {
    setState(() {
      if (colonnaOrdinata == colonna) {
        ordineCrescente = !ordineCrescente;
      } else {
        colonnaOrdinata = colonna;
        ordineCrescente = true;
      }

      if (colonna == 'nome') {
        discentiFiltrati.sort((a, b) {
          return ordineCrescente
              ? a.nome.compareTo(b.nome)
              : b.nome.compareTo(a.nome);
        });
      }

      if (colonna == 'cognome') {
        discentiFiltrati.sort((a, b) {
          return ordineCrescente
              ? a.cognome.compareTo(b.cognome)
              : b.cognome.compareTo(a.cognome);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Discenti',
          subtitle: 'Archivio partecipanti, anagrafiche e storico formativo.',
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: AppSearchBar(
                hintText: 'Cerca per nome, cognome, codice fiscale, impresa...',
                onChanged: cercaDiscenti,
              ),
            ),
            const SizedBox(width: 16),

            OutlinedButton.icon(
              onPressed: discentiFiltrati.isEmpty ? null : esportaExcelDiscenti,
              icon: const Icon(Icons.table_chart_rounded),
              label: Text('Export Excel (${discentiFiltrati.length})'),
            ),

            const SizedBox(width: 12),

            OutlinedButton.icon(
              onPressed: discentiFiltrati.isEmpty
                  ? null
                  : () async {
                      await PdfExportService.esportaTabella(
                        titolo: 'Discenti',
                        intestazioni: [
                          'Nome',
                          'Cognome',
                          'Luogo nascita',
                          'Data nascita',
                          'Codice fiscale',
                          'Impresa',
                        ],
                        righe: discentiFiltrati.map((d) {
                          return [
                            testoVuoto(d.nome),
                            testoVuoto(d.cognome),
                            testoVuoto(d.luogoNascita),
                            testoVuoto(d.dataNascita),
                            testoVuoto(d.codiceFiscale),
                            testoVuoto(d.nomeImpresa),
                          ];
                        }).toList(),
                      );
                    },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text('Export PDF (${discentiFiltrati.length})'),
            ),

            OutlinedButton.icon(
              onPressed: discentiFiltrati.isEmpty ? null : stampaDiscenti,
              icon: const Icon(Icons.print_rounded),
              label: Text('Stampa (${discentiFiltrati.length})'),
            ),

            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed: () => apriDialogDiscente(),
              icon: const Icon(Icons.add),
              label: const Text('Nuovo discente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SectionCard(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Archivio Discenti',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Text(
                            '${discentiFiltrati.length} ${discentiFiltrati.length == 1 ? 'record' : 'record'}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: discentiFiltrati.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nessun discente trovato',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  color: Colors.white,
                                  child: Scrollbar(
                                    controller: _horizontalController,
                                    thumbVisibility: true,
                                    radius: const Radius.circular(10),
                                    thickness: 7,
                                    child: SingleChildScrollView(
                                      controller: _horizontalController,
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: discentiTableWidth,
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: DiscentiHeader(
                                                onOrdina: ordinaDiscenti,
                                                colonnaOrdinata:
                                                    colonnaOrdinata,
                                                ordineCrescente:
                                                    ordineCrescente,
                                              ),
                                            ),
                                            Expanded(
                                              child: Scrollbar(
                                                controller: _verticalController,
                                                thumbVisibility: true,
                                                radius: const Radius.circular(
                                                  10,
                                                ),
                                                thickness: 7,
                                                child: ListView.builder(
                                                  controller:
                                                      _verticalController,
                                                  primary: false,
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  itemExtent: discenteRowHeight,
                                                  itemCount:
                                                      discentiFiltrati.length,
                                                  itemBuilder: (context, index) {
                                                    final d =
                                                        discentiFiltrati[index];

                                                    return DiscenteRow(
                                                      discente: d,
                                                      selezionata:
                                                          discenteSelezionatoId ==
                                                          d.id,
                                                      onSeleziona: () {
                                                        setState(() {
                                                          discenteSelezionatoId =
                                                              d.id;
                                                        });
                                                      },
                                                      onDoppioClick: () async {
                                                        final risultato =
                                                            await Navigator.of(
                                                              context,
                                                            ).push(
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    DiscenteSchedaPage(
                                                                      discente:
                                                                          d,
                                                                    ),
                                                              ),
                                                            );

                                                        if (risultato ==
                                                            'modifica') {
                                                          await apriDialogDiscente(
                                                            discente: d,
                                                          );
                                                        }

                                                        await caricaDati();
                                                      },
                                                      onModifica: () =>
                                                          apriDialogDiscente(
                                                            discente: d,
                                                          ),
                                                      onElimina: () =>
                                                          eliminaDiscente(d),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class DiscentiHeader extends StatelessWidget {
  final void Function(String colonna) onOrdina;

  final String colonnaOrdinata;
  final bool ordineCrescente;

  const DiscentiHeader({
    super.key,
    required this.onOrdina,
    required this.colonnaOrdinata,
    required this.ordineCrescente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: discenteRowHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: colNome,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOrdina('nome'),
              child: _HeaderCell(
                'Nome',
                ordinata: colonnaOrdinata == 'nome',
                crescente: ordineCrescente,
              ),
            ),
          ),
          SizedBox(
            width: colCognome,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOrdina('cognome'),
              child: _HeaderCell(
                'Cognome',
                ordinata: colonnaOrdinata == 'cognome',
                crescente: ordineCrescente,
              ),
            ),
          ),
          SizedBox(
            width: colLuogoNascita,
            child: const _HeaderCell('Luogo nascita'),
          ),
          SizedBox(
            width: colDataNascita,
            child: const _HeaderCell('Data nascita'),
          ),
          SizedBox(
            width: colCodiceFiscale,
            child: const _HeaderCell('Codice fiscale'),
          ),
          SizedBox(width: colImpresa, child: const _HeaderCell('Impresa')),
          const SizedBox(width: colAzioni, child: _HeaderCell('Azioni')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool ordinata;
  final bool crescente;

  const _HeaderCell(this.text, {this.ordinata = false, this.crescente = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          if (ordinata) ...[
            const SizedBox(width: 4),
            Icon(
              crescente ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: const Color(0xFF2563EB),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscenteCell extends StatelessWidget {
  final String? testo;

  const _DiscenteCell(this.testo);

  @override
  Widget build(BuildContext context) {
    final valore = testo == null || testo!.trim().isEmpty ? '-' : testo!.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          valore,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class DiscenteRow extends StatelessWidget {
  final Discente discente;

  final bool selezionata;

  final VoidCallback onSeleziona;
  final VoidCallback onModifica;
  final VoidCallback onElimina;
  final VoidCallback onDoppioClick;

  const DiscenteRow({
    super.key,
    required this.discente,
    required this.selezionata,
    required this.onSeleziona,
    required this.onModifica,
    required this.onElimina,
    required this.onDoppioClick,
  });

  @override
  Widget build(BuildContext context) {
    final coloreSfondo = selezionata ? const Color(0xFFDCEBFF) : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: coloreSfondo,
        child: InkWell(
          onTap: onSeleziona,
          onDoubleTap: onDoppioClick,
          hoverColor: const Color(0xFFF1F5F9),
          child: SizedBox(
            height: discenteRowHeight,
            child: Row(
              children: [
                Container(
                  width: 4,
                  color: selezionata
                      ? const Color(0xFF2563EB)
                      : Colors.transparent,
                ),
                SizedBox(
                  width: colNome - 4,
                  child: _DiscenteCell(discente.nome),
                ),
                SizedBox(
                  width: colCognome,
                  child: _DiscenteCell(discente.cognome),
                ),
                SizedBox(
                  width: colLuogoNascita,
                  child: _DiscenteCell(discente.luogoNascita),
                ),
                SizedBox(
                  width: colDataNascita,
                  child: _DiscenteCell(discente.dataNascita),
                ),
                SizedBox(
                  width: colCodiceFiscale,
                  child: _DiscenteCell(discente.codiceFiscale),
                ),
                SizedBox(
                  width: colImpresa,
                  child: _DiscenteCell(discente.nomeImpresa),
                ),
                SizedBox(
                  width: colAzioni,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Modifica',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF2563EB),
                        ),
                        onPressed: onModifica,
                      ),
                      IconButton(
                        tooltip: 'Elimina',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFDC2626),
                        ),
                        onPressed: onElimina,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
