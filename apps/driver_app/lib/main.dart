import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/app_module.dart';
import 'package:driver_app/app_widget.dart';
import 'package:driver_app/src/core/constants/env_config.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/location/location_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundTelemetryService.stopExistingServiceForStartup();
  final prefs = await SharedPreferences.getInstance();
  final sessionService = SecureSessionService();
  final hasDriverSession = await _hasDriverSession(sessionService);

  await dotenv.load(fileName: '.env', isOptional: true);

  late final MapNativeService nativeService;
  try {
    nativeService = MapNativeService(
      placeServiceBaseUri: EnvConfig.placeServiceUri,
    );
  } on StateError catch (error) {
    runApp(_ConfigurationErrorApp(message: error.message));
    return;
  }
  LocationService.nativeService = nativeService;
  final mapboxToken = EnvConfig.mapboxPublicToken;
  if (mapboxToken == null) {
    debugPrint('Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.');
  } else {
    await MapProvider.initialize(
      token: mapboxToken,
      nativeService: nativeService,
    );
  }

  await Modular.configure(
    appModule: AppModule(prefs: prefs, sessionService: sessionService),
    initialRoute: hasDriverSession
        ? DriverLocationRoutes.fullGatePath
        : AuthRoutes.signinPath,
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}

Future<bool> _hasDriverSession(SecureSessionService sessionService) async {
  try {
    return await sessionService.hasValidDriverSession();
  } catch (_) {
    return false;
  }
}

class _ConfigurationErrorApp extends StatelessWidget {
  final String message;

  const _ConfigurationErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$message\n\nSet API_BASE_URL in apps/driver_app/.env or pass '
              '--dart-define=API_BASE_URL=... when starting Driver.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
