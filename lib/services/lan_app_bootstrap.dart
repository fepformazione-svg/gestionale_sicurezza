import 'lan_client_configuration.dart';
import 'lan_client_runtime.dart';

class LanAppBootstrap {
  const LanAppBootstrap._();

  static LanClientRuntime? fromEnvironment(
    Map<String, String> environment, {
    LanClientBindingsFactory? bindingsFactory,
  }) {
    final configuration = LanClientConfiguration.fromEnvironment(environment);

    if (configuration == null) {
      return null;
    }

    return LanClientRuntime.fromConfiguration(
      configuration,
      bindingsFactory: bindingsFactory,
    );
  }
}
