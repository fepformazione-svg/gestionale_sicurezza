import 'dart:io';

import 'lan_api_client.dart';
import 'lan_client_configuration.dart';

typedef LanDiscentiProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanImpreseProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanCorsiProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanPrenotazioniProvider =
    Future<Map<String, dynamic>> Function({
      required int limit,
      required int offset,
      required String ricerca,
      required String filtro,
    });
typedef LanIntestazioneAziendaProvider = Future<Map<String, String>> Function();

typedef LanCloseCallback = Future<void> Function();

typedef LanClientBindingsFactory =
    LanClientBindings Function(LanClientConfiguration configuration);

class LanClientBindings {
  const LanClientBindings({
    required this.loadDiscenti,
    this.loadImprese,
    this.loadCorsi,
    this.loadPrenotazioni,
    this.loadIntestazioneAzienda,
    required this.close,
  });

  final LanDiscentiProvider loadDiscenti;
  final LanImpreseProvider? loadImprese;
  final LanCorsiProvider? loadCorsi;
  final LanPrenotazioniProvider? loadPrenotazioni;
  final LanIntestazioneAziendaProvider? loadIntestazioneAzienda;
  final LanCloseCallback close;
}

class LanClientRuntime {
  LanClientRuntime._({
    required this.enabled,
    required this.discentiProvider,
    required this.impreseProvider,
    required this.corsiProvider,
    required this.prenotazioniProvider,
    required this.intestazioneAziendaProvider,
    required this._closeCallback,
  });

  factory LanClientRuntime.fromConfiguration(
    LanClientConfiguration? configuration, {
    LanClientBindingsFactory? bindingsFactory,
  }) {
    if (configuration == null) {
      return LanClientRuntime._(
        enabled: false,
        discentiProvider: null,
        impreseProvider: null,
        corsiProvider: null,
        prenotazioniProvider: null,
        intestazioneAziendaProvider: null,
        closeCallback: null,
      );
    }

    final factory = bindingsFactory ?? _defaultBindingsFactory;

    final bindings = factory(configuration);

    return LanClientRuntime._(
      enabled: true,
      discentiProvider: bindings.loadDiscenti,
      impreseProvider: bindings.loadImprese,
      corsiProvider: bindings.loadCorsi,
      prenotazioniProvider: bindings.loadPrenotazioni,
      intestazioneAziendaProvider: bindings.loadIntestazioneAzienda,
      closeCallback: bindings.close,
    );
  }

  final bool enabled;

  final LanDiscentiProvider? discentiProvider;

  final LanImpreseProvider? impreseProvider;
  final LanCorsiProvider? corsiProvider;
  final LanPrenotazioniProvider? prenotazioniProvider;
  final LanIntestazioneAziendaProvider? intestazioneAziendaProvider;

  final LanCloseCallback? _closeCallback;

  bool _closed = false;

  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;

    final callback = _closeCallback;

    if (callback != null) {
      await callback();
    }
  }

  static LanClientBindings _defaultBindingsFactory(
    LanClientConfiguration configuration,
  ) {
    final caCertificatePath = configuration.caCertificatePath;
    SecurityContext? securityContext;

    if (caCertificatePath != null) {
      if (caCertificatePath.trim().isEmpty ||
          Uri.parse(configuration.baseUrl).scheme != 'https') {
        throw ArgumentError('Certificato CA LAN utilizzabile solo con HTTPS.');
      }

      // Contesto isolato: solo la CA LAN esplicitamente fornita e attendibile.
      // Nessun badCertificateCallback che aggiri la verifica TLS.
      securityContext = SecurityContext()
        ..setTrustedCertificates(caCertificatePath);
    }

    final client = LanApiClient(
      baseUrl: configuration.baseUrl,
      apiToken: configuration.apiToken,
      securityContext: securityContext,
    );

    return LanClientBindings(
      loadDiscenti: client.loadDiscenti,
      loadImprese: client.loadImprese,
      loadCorsi: client.loadCorsi,
      loadPrenotazioni: client.loadPrenotazioni,
      loadIntestazioneAzienda: client.loadIntestazioneAzienda,
      close: client.close,
    );
  }
}
