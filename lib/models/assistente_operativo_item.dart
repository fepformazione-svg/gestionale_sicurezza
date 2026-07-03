enum PrioritaAssistenteOperativo { alta, media, bassa }

enum ModuloAssistenteOperativo {
  dashboard,
  prenotazioni,
  diario,
  scadenze,
  discenti,
  imprese,
  consensiPrivacy,
  visiteMediche,
}

class AssistenteOperativoItem {
  final String titolo;
  final String descrizione;
  final int conteggio;
  final PrioritaAssistenteOperativo priorita;
  final ModuloAssistenteOperativo modulo;
  final String? azioneSuggerita;

  const AssistenteOperativoItem({
    required this.titolo,
    required this.descrizione,
    required this.conteggio,
    required this.priorita,
    required this.modulo,
    this.azioneSuggerita,
  });

  bool get haElementi => conteggio > 0;
}
