import 'package:driver_app/src/core/config/app_environment.dart';
import 'package:driver_app/src/core/config/env_config.dart';

class EnvironmentConfig {
  EnvironmentConfig._();

  static const AppEnvironment currentEnvironment = AppEnvironment.development;

  static String get httpBaseUrl {
    final baseUrl = EnvConfig.driverServiceUrl;
    // Replace the driver service port (8082) with the gateway port (8080)
    return baseUrl.replaceAll('8082', '8080');
  }

  static String get webSocketBaseUrl {
    final httpUrl = httpBaseUrl;
    final wsScheme = httpUrl.startsWith('https') ? 'wss' : 'ws';
    final hostPort = httpUrl.replaceAll('https://', '').replaceAll('http://', '');
    return '$wsScheme://$hostPort';
  }
}
