import 'dart:async';

import 'package:flutter/material.dart';

import '../services/lan_client_runtime.dart';

/// Vista di consultazione LAN: non apre database locali e non espone scritture.
class PrenotazioniLanPage extends StatefulWidget {
  const PrenotazioniLanPage({
    super.key,
    required this.prenotazioniProvider,
    this.globalSearch = '',
    this.filtro = 'tutte',
  });

  final LanPrenotazioniProvider? prenotazioniProvider;
  final String globalSearch;
  final String filtro;

  @override
  State<PrenotazioniLanPage> createState() => _PrenotazioniLanPageState();
}

class _PrenotazioniLanPageState extends State<PrenotazioniLanPage> {
  static const int _pageSize = 50;
  static const Map<String, String> _filtri = {
    'tutte': 'Tutte',
    'aperte': 'Aperte',
    'registro': 'Registro',
    'chiuse': 'Chiuse',
    'da_fare': 'Da fare',
    'senza_discente': 'Senza discente',
    'aziendali_senza_discente': 'Aziendali senza discente',
    'senza_docente': 'Senza docente',
    'recenti_da_sistemare': 'Recenti da sistemare',
  };

  late final TextEditingController _ricercaController;
  late String _filtro;
  Timer? _debounce;
  int _requestId = 0;
  int _offset = 0;
  bool _loading = false;
  String? _errore;
  List<Map<String, dynamic>> _prenotazioni = const [];
  Map<String, int> _conteggi = const {};

  @override
  void initState() {
    super.initState();
    _ricercaController = TextEditingController(text: widget.globalSearch);
    _filtro = _filtri.containsKey(widget.filtro) ? widget.filtro : 'tutte';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _caricaPagina(offset: 0);
    });
  }

  @override
  void didUpdateWidget(covariant PrenotazioniLanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    var ricarica = false;

    if (widget.globalSearch != oldWidget.globalSearch) {
      _ricercaController.text = widget.globalSearch;
      ricarica = true;
    }

    if (widget.filtro != oldWidget.filtro) {
      _filtro = _filtri.containsKey(widget.filtro) ? widget.filtro : 'tutte';
      ricarica = true;
    }

    if (widget.prenotazioniProvider != oldWidget.prenotazioniProvider) {
      ricarica = true;
    }

    if (ricarica) {
      _debounce?.cancel();
      _caricaPagina(offset: 0);
    }
  }

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _ricercaController.dispose();
    super.dispose();
  }

  void _cambiaRicerca(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _caricaPagina(offset: 0);
    });
  }

  void _cambiaFiltro(String filtro) {
    if (_filtro == filtro) return;
    _debounce?.cancel();
    setState(() => _filtro = filtro);
    _caricaPagina(offset: 0);
  }

  Future<void> _caricaPagina({required int offset}) async {
    final richiesta = ++_requestId;
    final provider = widget.prenotazioniProvider;

    if (provider == null) {
      setState(() {
        _errore = 'Servizio Prenotazioni LAN non disponibile.';
        _prenotazioni = const [];
        _conteggi = const {};
        _loading = false;
        _offset = 0;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errore = null;
    });

    try {
      final risposta = await provider(
        limit: _pageSize,
        offset: offset,
        ricerca: _ricercaController.text.trim(),
        filtro: _filtro,
      );

      final rawItems = risposta['items'];
      final rawConteggi = risposta['conteggi'];

      if (rawItems is! List || rawConteggi is! Map) {
        throw const FormatException('Risposta Prenotazioni LAN non valida.');
      }

      final elementi = <Map<String, dynamic>>[];
      for (final item in rawItems) {
        if (item is! Map) {
          throw const FormatException('Prenotazione LAN non valida.');
        }
        elementi.add(Map<String, dynamic>.from(item));
      }

      final conteggi = <String, int>{};
      for (final entry in rawConteggi.entries) {
        if (entry.key is! String || entry.value is! int) {
          throw const FormatException('Conteggi Prenotazioni LAN non validi.');
        }
        conteggi[entry.key as String] = entry.value as int;
      }

      if (!mounted || richiesta != _requestId) return;
      setState(() {
        _prenotazioni = List<Map<String, dynamic>>.unmodifiable(elementi);
        _conteggi = Map<String, int>.unmodifiable(conteggi);
        _offset = offset;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || richiesta != _requestId) return;
      setState(() {
        _prenotazioni = const [];
        _conteggi = const {};
        _errore = 'Impossibile caricare le Prenotazioni LAN: $error';
        _loading = false;
      });
    }
  }

  String _testo(Object? value) => value?.toString().trim() ?? '';

  bool _attivo(Object? value) =>
      value == true || value == 1 || value?.toString() == '1';

  String _discente(Map<String, dynamic> prenotazione) {
    final cognome = _testo(prenotazione['discente_cognome']);
    final nome = _testo(prenotazione['discente_nome']);
    return '$cognome $nome'.trim();
  }

  String _stato(Map<String, dynamic> prenotazione) {
    if (_attivo(prenotazione['registro'])) return 'REGISTRO';
    if (_attivo(prenotazione['conferma'])) return 'CHIUSO';
    if (_attivo(prenotazione['aperto'])) return 'APERTO';
    return 'DA FARE';
  }

  @override
  Widget build(BuildContext context) {
    final disponibile = widget.prenotazioniProvider != null;
    final totale = _conteggi[_filtro] ?? 0;
    final pagina = (_offset ~/ _pageSize) + 1;
    final avanti =
        disponibile &&
        !_loading &&
        _prenotazioni.length == _pageSize &&
        _offset + _prenotazioni.length < totale;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Prenotazioni',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Chip(
                  avatar: Icon(Icons.lock_outline, size: 17),
                  label: Text('LAN - SOLA LETTURA'),
                  backgroundColor: Color(0xFFE3F2FD),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ricercaController,
              enabled: disponibile,
              onChanged: _cambiaRicerca,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Cerca discente, impresa, corso, data o protocollo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 5,
              children: [
                for (final filtro in _filtri.entries)
                  ChoiceChip(
                    label: Text(
                      '${filtro.value} (${_conteggi[filtro.key] ?? 0})',
                    ),
                    selected: _filtro == filtro.key,
                    onSelected: disponibile && !_loading
                        ? (_) => _cambiaFiltro(filtro.key)
                        : null,
                  ),
              ],
            ),
            if (_errore != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errore!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _prenotazioni.isEmpty
                  ? const Center(
                      child: Text('Nessuna prenotazione da mostrare.'),
                    )
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Discente')),
                            DataColumn(label: Text('Impresa')),
                            DataColumn(label: Text('Corso')),
                            DataColumn(label: Text('Data')),
                            DataColumn(label: Text('Protocollo')),
                            DataColumn(label: Text('Stato')),
                            DataColumn(label: Text('Attrezzature')),
                          ],
                          rows: [
                            for (final prenotazione in _prenotazioni)
                              DataRow(
                                cells: [
                                  DataCell(Text(_discente(prenotazione))),
                                  DataCell(
                                    Text(_testo(prenotazione['impresa_nome'])),
                                  ),
                                  DataCell(
                                    Text(_testo(prenotazione['corso_nome'])),
                                  ),
                                  DataCell(Text(_testo(prenotazione['data']))),
                                  DataCell(Text(_testo(prenotazione['prot']))),
                                  DataCell(Text(_stato(prenotazione))),
                                  DataCell(
                                    Text(
                                      _testo(
                                        prenotazione['attrezzature_sintesi'],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pagina $pagina - ${_prenotazioni.length} record visibili su $totale',
                  ),
                ),
                IconButton(
                  tooltip: 'Aggiorna dati LAN',
                  onPressed: disponibile && !_loading
                      ? () => _caricaPagina(offset: _offset)
                      : null,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Pagina precedente',
                  onPressed: disponibile && !_loading && _offset > 0
                      ? () => _caricaPagina(offset: _offset - _pageSize)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Pagina successiva',
                  onPressed: avanti
                      ? () => _caricaPagina(offset: _offset + _pageSize)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
