import 'lan_api_client.dart';
import 'lan_client_configuration.dart';

typedef LanDiscentiProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanImpreseProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanCorsiProvider = Future<List<Map<String, dynamic>>> Function();
typedef LanIntestazioneAziendaProvider = Future<Map<String, String>> Function();

typedef LanCloseCallback = Future<void> Function();

typedef LanClientBindingsFactory =
    LanClientBindings Function(LanClientConfiguration configuration);

class LanClientBindings {
  const LanClientBindings({
    required this.loadDiscenti,
    this.loadImprese,
    this.loadCorsi,
    this.loadIntestazioneAzienda,
    required this.close,
  });

  final LanDiscentiProvider loadDiscenti;
  final LanImpreseProvider? loadImprese;
  final LanCorsiProvider? loadCorsi;
  final LanIntestazioneAziendaProvider? loadIntestazioneAzienda;
  final LanCloseCallback close;
}

class LanClientRuntime {
  LanClientRuntime._({
    required this.enabled,
    required this.discentiProvider,
    required this.impreseProvider,
    required this.corsiProvider,
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
      intestazioneAziendaProvider: bindings.loadIntestazioneAzienda,
      closeCallback: bindings.close,
    );
  }

  final bool enabled;

  final LanDiscentiProvider? discentiProvider;

  final LanImpreseProvider? impreseProvider;
  final LanCorsiProvider? corsiProvider;
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
    final client = LanApiClient(
      baseUrl: configuration.baseUrl,
      apiToken: configuration.apiToken,
    );

    return LanClientBindings(
      loadDiscenti: client.loadDiscenti,
      loadImprese: client.loadImprese,
      loadCorsi: client.loadCorsi,
      loadIntestazioneAzienda: client.loadIntestazioneAzienda,
      close: client.close,
    );
  }
}
