import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../dialogs/discente_dialog.dart';
import 'discente_scheda_page.dart';

class DiarioPage extends StatefulWidget {
  final bool soloDaFatturare;

  const DiarioPage({super.key, this.soloDaFatturare = false});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  int? rinnovoInCorsoId;

  final TextEditingController _cercaController = TextEditingController();
  final ScrollController diarioHorizontalController = ScrollController();

  List<Map<String, dynamic>> _diario = [];
  bool _caricamento = true;
  bool _soloDaFatturare = false;

  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _soloDaFatturare = widget.soloDaFatturare;
    caricaDiario();
  }

  Future<void> caricaDiario() async {
    setState(() => _caricamento = true);

    final dati = await DatabaseService.instance.caricaDiario(
      ricerca: _cercaController.text.trim(),
    );

    final ricerca = _cercaController.text.trim().toLowerCase();

    final datiFiltrati = ricerca.isEmpty
        ? dati
        : dati.where((riga) {
            final discente = '${testo(riga['cognome'])} ${testo(riga['nome'])}'
                .toLowerCase();
            final impresa = testo(riga['impresa']).toLowerCase();
            final corso = testo(riga['corso']).toLowerCase();
            final prot = testo(riga['prot']).toLowerCase();
            final data = testo(riga['data']).toLowerCase();
            final scadenza = testo(riga['scadenza']).toLowerCase();

            return discente.contains(ricerca) ||
                impresa.contains(ricerca) ||
                corso.contains(ricerca) ||
                prot.contains(ricerca) ||
                data.contains(ricerca) ||
                scadenza.contains(ricerca);
          }).toList();

    if (!mounted) return;

    setState(() {
      _diario = _soloDaFatturare
          ? datiFiltrati.where((riga) => riga['da_fatturare'] == 1).toList()
          : datiFiltrati;

      _caricamento = false;
    });
  }

  void ordina<T>(
    Comparable<T> Function(Map<String, dynamic> riga) getField,
    int columnIndex,
    bool ascending,
  ) {
    _diario.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);

      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  String statoScadenza(String? dataScadenza) {
    if (dataScadenza == null || dataScadenza.isEmpty) {
      return 'N/D';
    }

    final oggi = DateTime.now();
    final scadenza = DateTime.tryParse(dataScadenza);

    if (scadenza == null) return 'N/D';

    final giorni = scadenza.difference(oggi).inDays;

    if (giorni < 0) return 'SCADUTO';
    if (giorni <= 60) return 'IN SCADENZA';
    return 'VALIDO';
  }

  Color coloreStato(String stato) {
    switch (stato) {
      case 'SCADUTO':
        return Colors.red;
      case 'IN SCADENZA':
        return Colors.orange;
      case 'VALIDO':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget badge(String testo) {
    final colore = coloreStato(testo);

    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colore.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Text(
          testo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colore,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget badgeDaFatturare(bool valore) {
    return Tooltip(
      message: valore ? 'Da fatturare' : 'Non da fatturare',
      child: Container(
        width: 98,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: valore ? const Color(0xFFFFEDD5) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: valore ? const Color(0xFFF97316) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valore
                  ? Icons.receipt_long_rounded
                  : Icons.check_circle_outline_rounded,
              size: 15,
              color: valore ? const Color(0xFFC2410C) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              valore ? 'DA FATT' : 'OK',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: valore
                    ? const Color(0xFFC2410C)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String testo(dynamic valore) {
    if (valore == null) return '';
    return valore.toString();
  }

  String formattaData(dynamic valore) {
    if (valore == null || valore.toString().trim().isEmpty) return '-';

    final testoData = valore.toString().trim();

    try {
      DateTime? data;

      if (testoData.contains('/')) {
        final parti = testoData.split('/');
        if (parti.length == 3) {
          data = DateTime(
            int.parse(parti[2]),
            int.parse(parti[1]),
            int.parse(parti[0]),
          );
        }
      } else {
        data = DateTime.tryParse(testoData);
      }

      if (data == null) return testoData;

      final giorno = data.day.toString().padLeft(2, '0');
      final mese = data.month.toString().padLeft(2, '0');
      final anno = data.year.toString();

      return '$giorno/$mese/$anno';
    } catch (_) {
      return testoData;
    }
  }

  @override
  void dispose() {
    _cercaController.dispose();
    diarioHorizontalController.dispose();
    super.dispose();
  }

  Future<void> apriSchedaDiscente(Map<String, dynamic> riga) async {
    final idDiscente = riga['discente_id'];

    if (idDiscente == null) return;

    final discente = await DatabaseService.instance.getDiscenteById(idDiscente);

    if (discente == null) return;
    if (!mounted) return;

    final risultato = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DiscenteSchedaPage(discente: discente)),
    );

    if (!mounted) return;

    if (risultato == 'modifica') {
      final salvato = await apriDialogDiscente(
        context: context,
        discente: discente,
      );

      if (salvato) {
        await caricaDiario();
      }

      return;
    }

    if (risultato == true) {
      await caricaDiario();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIARIO CORSI',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _cercaController,
              onChanged: (_) => caricaDiario(),
              decoration: InputDecoration(
                hintText: 'Cerca discente, impresa, corso, protocollo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cercaController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Azzera ricerca',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cercaController.clear();
                          caricaDiario();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                if (_cercaController.text.trim().isNotEmpty)
                  Tooltip(
                    message: 'Clicca per azzerare la ricerca',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        _cercaController.clear();
                        caricaDiario();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.manage_search_rounded,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ricerca attiva: ${_cercaController.text.trim()}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_soloDaFatturare) ...[
                  if (_cercaController.text.trim().isNotEmpty)
                    const SizedBox(width: 8),
                  Tooltip(
                    message: 'Clicca per mostrare tutto il diario',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() {
                          _soloDaFatturare = false;
                        });

                        caricaDiario();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 15,
                              color: Color(0xFFF97316),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Filtro attivo: Da fatturare',
                              style: TextStyle(
                                color: Color(0xFFF97316),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFFF97316),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 8),
                Tooltip(
                  message:
                      _cercaController.text.trim().isNotEmpty ||
                          _soloDaFatturare
                      ? 'Mostra tutto il diario rimuovendo ricerca e filtro'
                      : 'Tutto il diario è già visibile',
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cercaController.clear();
                        _soloDaFatturare = false;
                      });

                      caricaDiario();
                    },
                    icon: Icon(
                      _cercaController.text.trim().isNotEmpty ||
                              _soloDaFatturare
                          ? Icons.filter_alt_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _cercaController.text.trim().isNotEmpty ||
                              _soloDaFatturare
                          ? 'Mostra tutto'
                          : 'Tutto visibile',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _cercaController.text.trim().isNotEmpty ||
                              _soloDaFatturare
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      side: BorderSide(
                        color:
                            _cercaController.text.trim().isNotEmpty ||
                                _soloDaFatturare
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _cercaController.text.trim().isNotEmpty
                            ? _soloDaFatturare
                                  ? _diario.length == 1
                                        ? '1 corso da fatturare trovato'
                                        : '${_diario.length} corsi da fatturare trovati'
                                  : _diario.length == 1
                                  ? '1 corso trovato'
                                  : '${_diario.length} corsi trovati'
                            : _soloDaFatturare
                            ? _diario.length == 1
                                  ? '1 corso da fatturare'
                                  : '${_diario.length} corsi da fatturare'
                            : _diario.length == 1
                            ? '1 corso visualizzato'
                            : '${_diario.length} corsi visualizzati',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _caricamento
                  ? const Center(child: CircularProgressIndicator())
                  : _diario.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 52,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _cercaController.text.trim().isNotEmpty
                                  ? _soloDaFatturare
                                        ? 'Nessun corso da fatturare trovato'
                                        : 'Nessun corso trovato'
                                  : _soloDaFatturare
                                  ? 'Nessun corso da fatturare'
                                  : 'Nessun corso presente nel diario',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (_cercaController.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Prova a modificare o azzerare la ricerca.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _cercaController.clear();
                                  });

                                  caricaDiario();
                                },
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                label: const Text('Azzera ricerca'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            controller: diarioHorizontalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            interactive: true,
                            child: SingleChildScrollView(
                              controller: diarioHorizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth < 1600
                                      ? 1600
                                      : constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _sortAscending,
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade100,
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: const SizedBox(
                                          width: 150,
                                          child: Text('Discente'),
                                        ),
                                        onSort: (columnIndex, ascending) {
                                          ordina<String>(
                                            (riga) =>
                                                '${testo(riga['cognome'])} ${testo(riga['nome'])}',
                                            columnIndex,
                                            ascending,
                                          );
                                        },
                                      ),
                                      DataColumn(
                                        label: const SizedBox(
                                          width: 130,
                                          child: Text('Impresa'),
                                        ),
                                        onSort: (columnIndex, ascending) {
                                          ordina<String>(
                                            (riga) => testo(riga['impresa']),
                                            columnIndex,
                                            ascending,
                                          );
                                        },
                                      ),
                                      DataColumn(
                                        label: const SizedBox(
                                          width: 180,
                                          child: Text('Corso'),
                                        ),
                                        onSort: (columnIndex, ascending) {
                                          ordina<String>(
                                            (riga) => testo(riga['corso']),
                                            columnIndex,
                                            ascending,
                                          );
                                        },
                                      ),
                                      const DataColumn(
                                        label: SizedBox(
                                          width: 105,
                                          child: Center(
                                            child: Text('Data corso'),
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: const SizedBox(
                                          width: 105,
                                          child: Center(
                                            child: Text('Scadenza'),
                                          ),
                                        ),
                                        onSort: (columnIndex, ascending) {
                                          ordina<String>(
                                            (riga) => testo(riga['scadenza']),
                                            columnIndex,
                                            ascending,
                                          );
                                        },
                                      ),
                                      const DataColumn(
                                        label: SizedBox(
                                          width: 90,
                                          child: Center(child: Text('Stato')),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: SizedBox(
                                          width: 70,
                                          child: Center(child: Text('Prot.')),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: Tooltip(
                                          message:
                                              'Numero o riferimento fattura',
                                          child: SizedBox(
                                            width: 85,
                                            child: Center(
                                              child: Text('Fattura'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: Tooltip(
                                          message: 'Stato invio documentazione',
                                          child: SizedBox(
                                            width: 75,
                                            child: Center(child: Text('Invio')),
                                          ),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: Tooltip(
                                          message: 'Stato da fatturare',
                                          child: SizedBox(
                                            width: 85,
                                            child: Center(
                                              child: Text('Da Fatt.'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: Tooltip(
                                          message: 'Rinnova corso',
                                          child: SizedBox(
                                            width: 60,
                                            child: Center(
                                              child: Icon(
                                                Icons.refresh_rounded,
                                                size: 22,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: _diario.map((riga) {
                                      final idDiario = riga['id'] as int;
                                      final rinnovoQuestaRiga =
                                          rinnovoInCorsoId == idDiario;

                                      final stato = statoScadenza(
                                        riga['scadenza']?.toString(),
                                      );

                                      return DataRow(
                                        color:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((states) {
                                              if (rinnovoQuestaRiga) {
                                                return const Color(0xFFEFF6FF);
                                              }

                                              return null;
                                            }),
                                        onSelectChanged: (_) {
                                          apriSchedaDiscente(riga);
                                        },
                                        cells: [
                                          DataCell(
                                            InkWell(
                                              onTap: () {
                                                apriSchedaDiscente(riga);
                                              },
                                              child: Text(
                                                '${testo(riga['cognome'])} ${testo(riga['nome'])}'
                                                    .trim(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(testo(riga['impresa'])),
                                          ),
                                          DataCell(Text(testo(riga['corso']))),
                                          DataCell(
                                            SizedBox(
                                              width: 105,
                                              child: Center(
                                                child: Text(
                                                  formattaData(riga['data']),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 105,
                                              child: Center(
                                                child: Text(
                                                  formattaData(
                                                    riga['scadenza'],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 90,
                                              child: Center(
                                                child: badge(stato),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 70,
                                              child: Center(
                                                child: Text(
                                                  testo(riga['prot']),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 85,
                                              child: Center(
                                                child: Tooltip(
                                                  message:
                                                      testo(
                                                        riga['fattura'],
                                                      ).trim().isEmpty
                                                      ? 'Inserisci riferimento fattura'
                                                      : 'Modifica o rimuovi fattura: ${testo(riga['fattura']).trim()}',
                                                  child:
                                                      testo(
                                                        riga['fattura'],
                                                      ).trim().isEmpty
                                                      ? Container(
                                                          width: 72,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'NO',
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF64748B,
                                                              ),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 72,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFECFDF5,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFF10B981,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            testo(
                                                              riga['fattura'],
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  color: Color(
                                                                    0xFF047857,
                                                                  ),
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  letterSpacing:
                                                                      0.2,
                                                                ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            onTap: () async {
                                              final controller =
                                                  TextEditingController(
                                                    text: testo(
                                                      riga['fattura'],
                                                    ),
                                                  );

                                              final nuovaFattura = await showDialog<String>(
                                                context: context,
                                                builder: (dialogContext) {
                                                  return AlertDialog(
                                                    title: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .receipt_long_rounded,
                                                          color: Color(
                                                            0xFF047857,
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          'Riferimento fattura',
                                                        ),
                                                      ],
                                                    ),
                                                    content: TextField(
                                                      controller: controller,
                                                      autofocus: true,
                                                      decoration: const InputDecoration(
                                                        labelText:
                                                            'Numero o riferimento fattura',
                                                        hintText:
                                                            'Es. FPA 12/2026',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(null);
                                                        },
                                                        child: const Text(
                                                          'Annulla',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop('');
                                                        },
                                                        child: const Text(
                                                          'Svuota',
                                                        ),
                                                      ),
                                                      FilledButton.icon(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(
                                                            controller.text
                                                                .trim(),
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.save_rounded,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'Salva',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                              controller.dispose();

                                              if (nuovaFattura == null) return;

                                              await DatabaseService.instance
                                                  .aggiornaFatturaDiario(
                                                    idDiario: idDiario,
                                                    fattura: nuovaFattura,
                                                  );

                                              await caricaDiario();

                                              if (!mounted) return;

                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    nuovaFattura.trim().isEmpty
                                                        ? 'Riferimento fattura rimosso'
                                                        : 'Riferimento fattura salvato',
                                                  ),
                                                  backgroundColor:
                                                      nuovaFattura
                                                          .trim()
                                                          .isEmpty
                                                      ? const Color(0xFF64748B)
                                                      : const Color(0xFF047857),
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 75,
                                              child: Center(
                                                child: Tooltip(
                                                  message:
                                                      riga['invio']
                                                              ?.toString() ==
                                                          '1'
                                                      ? 'Rimuovi invio'
                                                      : 'Segna come inviato',
                                                  child:
                                                      riga['invio']
                                                              ?.toString() ==
                                                          '1'
                                                      ? Container(
                                                          width: 72,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFE0F2FE,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFF0284C7,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'INVIATO',
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF0369A1,
                                                              ),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 72,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: const Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'NO',
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF64748B,
                                                              ),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            onTap: () async {
                                              final invioAttivo =
                                                  riga['invio']?.toString() ==
                                                  '1';
                                              final nuovoValore = invioAttivo
                                                  ? 0
                                                  : 1;

                                              try {
                                                await DatabaseService.instance
                                                    .aggiornaInvioDiario(
                                                      idDiario: idDiario,
                                                      invio: nuovoValore,
                                                    );

                                                await caricaDiario();

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(
                                                  this.context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      nuovoValore == 1
                                                          ? 'Corso segnato come inviato'
                                                          : 'Invio rimosso',
                                                    ),
                                                    backgroundColor:
                                                        nuovoValore == 1
                                                        ? const Color(
                                                            0xFF2563EB,
                                                          )
                                                        : const Color(
                                                            0xFF64748B,
                                                          ),
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              } catch (errore) {
                                                if (!mounted) return;

                                                ScaffoldMessenger.of(
                                                  this.context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Errore aggiornamento invio: $errore',
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFFDC2626),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 108,
                                              child: Center(
                                                child: Tooltip(
                                                  message:
                                                      riga['da_fatturare'] == 1
                                                      ? 'Rimuovi da elenco da fatturare'
                                                      : 'Segna come da fatturare',
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    onTap: () async {
                                                      final attualmenteDaFatturare =
                                                          riga['da_fatturare'] ==
                                                          1;

                                                      await DatabaseService
                                                          .instance
                                                          .aggiornaDaFatturareDiario(
                                                            id: idDiario,
                                                            valore:
                                                                !attualmenteDaFatturare,
                                                          );

                                                      await caricaDiario();

                                                      if (!mounted) return;

                                                      ScaffoldMessenger.of(
                                                        this.context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            !attualmenteDaFatturare
                                                                ? 'Corso segnato come da fatturare'
                                                                : 'Corso rimosso da fatturare',
                                                          ),
                                                          backgroundColor:
                                                              !attualmenteDaFatturare
                                                              ? const Color(
                                                                  0xFFF97316,
                                                                )
                                                              : const Color(
                                                                  0xFF64748B,
                                                                ),
                                                          duration:
                                                              const Duration(
                                                                seconds: 3,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: badgeDaFatturare(
                                                      riga['da_fatturare'] == 1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 60,
                                              child: Center(
                                                child: IconButton(
                                                  tooltip: rinnovoQuestaRiga
                                                      ? 'Rinnovo in corso...'
                                                      : rinnovoInCorsoId != null
                                                      ? 'Attendi il completamento del rinnovo in corso'
                                                      : 'Rinnova corso',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 38,
                                                        minHeight: 38,
                                                      ),
                                                  splashRadius: 22,
                                                  icon: rinnovoQuestaRiga
                                                      ? const SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.2,
                                                              ),
                                                        )
                                                      : Container(
                                                          width: 34,
                                                          height: 34,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                rinnovoInCorsoId !=
                                                                    null
                                                                ? const Color(
                                                                    0xFFF1F5F9,
                                                                  )
                                                                : const Color(
                                                                    0xFFEFF6FF,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  rinnovoInCorsoId !=
                                                                      null
                                                                  ? const Color(
                                                                      0xFFCBD5E1,
                                                                    )
                                                                  : const Color(
                                                                      0xFFBFDBFE,
                                                                    ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .refresh_rounded,
                                                            size: 19,
                                                            color:
                                                                rinnovoInCorsoId !=
                                                                    null
                                                                ? const Color(
                                                                    0xFF94A3B8,
                                                                  )
                                                                : const Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                          ),
                                                        ),
                                                  onPressed:
                                                      rinnovoInCorsoId != null
                                                      ? null
                                                      : () async {
                                                          final confermato = await showDialog<bool>(
                                                            context: context,
                                                            barrierDismissible:
                                                                false,
                                                            builder: (dialogContext) {
                                                              return AlertDialog(
                                                                title: const Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .refresh_rounded,
                                                                      color: Color(
                                                                        0xFF2563EB,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Text(
                                                                      'Conferma rinnovo corso',
                                                                    ),
                                                                  ],
                                                                ),
                                                                content: Text(
                                                                  'Vuoi creare un nuovo rinnovo per il corso '
                                                                  '"${testo(riga['corso'])}" di '
                                                                  '${testo(riga['cognome'])} ${testo(riga['nome'])}?',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.of(
                                                                        dialogContext,
                                                                      ).pop(
                                                                        false,
                                                                      );
                                                                    },
                                                                    child: const Text(
                                                                      'Annulla',
                                                                    ),
                                                                  ),
                                                                  FilledButton.icon(
                                                                    onPressed: () {
                                                                      Navigator.of(
                                                                        dialogContext,
                                                                      ).pop(
                                                                        true,
                                                                      );
                                                                    },
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .refresh_rounded,
                                                                      size: 18,
                                                                    ),
                                                                    label: const Text(
                                                                      'Rinnova',
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );

                                                          if (!mounted) return;
                                                          if (confermato !=
                                                              true) {
                                                            return;
                                                          }

                                                          final discenteId =
                                                              riga['discente_id'];
                                                          final impresaId =
                                                              riga['impresa_id'];
                                                          final corsoId =
                                                              riga['corso_id'];

                                                          if (discenteId ==
                                                                  null ||
                                                              impresaId ==
                                                                  null ||
                                                              corsoId == null) {
                                                            ScaffoldMessenger.of(
                                                              this.context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Impossibile rinnovare: discente, impresa o corso mancanti.',
                                                                ),
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          setState(() {
                                                            rinnovoInCorsoId =
                                                                idDiario;
                                                          });

                                                          try {
                                                            await DatabaseService
                                                                .instance
                                                                .rinnovaCorso(
                                                                  idDiscente:
                                                                      discenteId
                                                                          as int,
                                                                  idImpresa:
                                                                      impresaId
                                                                          as int,
                                                                  idCorso:
                                                                      corsoId
                                                                          as int,
                                                                );

                                                            await caricaDiario();

                                                            if (!mounted) {
                                                              return;
                                                            }

                                                            ScaffoldMessenger.of(
                                                              this.context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Rinnovo creato: ${testo(riga['corso'])} — '
                                                                  '${testo(riga['cognome'])} ${testo(riga['nome'])}',
                                                                ),
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFF16A34A,
                                                                    ),
                                                                duration:
                                                                    const Duration(
                                                                      seconds:
                                                                          4,
                                                                    ),
                                                              ),
                                                            );
                                                          } catch (errore) {
                                                            if (!mounted) {
                                                              return;
                                                            }

                                                            ScaffoldMessenger.of(
                                                              this.context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Errore durante il rinnovo: $errore',
                                                                ),
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFFDC2626,
                                                                    ),
                                                              ),
                                                            );
                                                          } finally {
                                                            if (mounted) {
                                                              setState(() {
                                                                rinnovoInCorsoId =
                                                                    null;
                                                              });
                                                            }
                                                          }
                                                        },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
