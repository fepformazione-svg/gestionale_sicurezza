import 'package:flutter/material.dart';

import '../models/discente.dart';
import '../models/impresa.dart';
import '../services/database_service.dart';
import '../widgets/app_search_bar.dart';

import 'discente_scheda_page.dart';

import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import '../services/pdf_export_service.dart';

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

    int? impresaId = discente?.impresaId;

    final salvato = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 720,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                              decoration: _inputDecoration('Data nascita'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: cfController,
                        decoration: _inputDecoration('Codice fiscale'),
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
                              decoration: _inputDecoration('Data visita'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: scadenzaVisitaController,
                              decoration: _inputDecoration('Scadenza visita'),
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

                              final nuovoDiscente = Discente(
                                id: discente?.id,
                                nome: nome,
                                cognome: cognome,
                                luogoNascita: luogoController.text.trim(),
                                dataNascita: dataController.text.trim(),
                                codiceFiscale: cfController.text.trim(),
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

    if (salvato == true) {
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
