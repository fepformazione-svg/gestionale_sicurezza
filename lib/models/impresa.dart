class Impresa {
  final int? id;

  final String intestazione;
  final String? partitaIva;
  final String? codiceFiscale;
  final String? indirizzo;
  final String? telefono;
  final String? referente;

  final int informativaPrivacyImpresaFirmata;
  final String? dataFirmaInformativaPrivacyImpresa;
  final String? documentoPrivacyImpresaPath;
  final String? notePrivacyImpresa;

  Impresa({
    this.id,
    required this.intestazione,
    this.partitaIva,
    this.codiceFiscale,
    this.indirizzo,
    this.telefono,
    this.referente,
    this.informativaPrivacyImpresaFirmata = 0,
    this.dataFirmaInformativaPrivacyImpresa,
    this.documentoPrivacyImpresaPath,
    this.notePrivacyImpresa,
  });

  factory Impresa.fromMap(Map<String, dynamic> map) {
    return Impresa(
      id: map['id'] as int?,
      intestazione: (map['intestazione'] ?? '').toString(),
      partitaIva: map['partita_iva']?.toString(),
      codiceFiscale: map['codice_fiscale']?.toString(),
      indirizzo: map['indirizzo']?.toString(),
      telefono: map['telefono']?.toString(),
      referente: map['referente']?.toString(),
      informativaPrivacyImpresaFirmata:
          (map['informativa_privacy_impresa_firmata'] as int?) ?? 0,
      dataFirmaInformativaPrivacyImpresa:
          map['data_firma_informativa_privacy_impresa']?.toString(),
      documentoPrivacyImpresaPath: map['documento_privacy_impresa_path']
          ?.toString(),
      notePrivacyImpresa: map['note_privacy_impresa']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'intestazione': intestazione,
      'partita_iva': partitaIva,
      'codice_fiscale': codiceFiscale,
      'indirizzo': indirizzo,
      'telefono': telefono,
      'referente': referente,
      'informativa_privacy_impresa_firmata': informativaPrivacyImpresaFirmata,
      'data_firma_informativa_privacy_impresa':
          dataFirmaInformativaPrivacyImpresa,
      'documento_privacy_impresa_path': documentoPrivacyImpresaPath,
      'note_privacy_impresa': notePrivacyImpresa,
    };
  }

  String get nome => intestazione;
}
