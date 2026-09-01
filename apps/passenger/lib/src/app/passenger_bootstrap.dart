import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/passenger_app.dart';
import 'package:passenger/src/app/passenger_dependencies.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/infrastructure/config/passenger_env_config.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapPassengerApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureClientErrorBoundary(appName: 'passenger-app');

  try {
    await PassengerBackgroundTelemetry.stopExistingServiceForStartup();
    final prefs = await SharedPreferences.getInstance();

    await dotenv.load(fileName: '.env', isOptional: true);

    final nativeService = MapNativeService(
      placeServiceBaseUri: PassengerEnvConfig.apiBaseUri,
    );
    LocationService.nativeService = nativeService;
    final mapboxToken = PassengerEnvConfig.mapboxPublicToken;
    if (mapboxToken == null) {
      debugPrint('Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.');
    }
    await MapProvider.initialize(
      token: mapboxToken,
      nativeService: nativeService,
    );

    AppTransitions.configure();

    await Modular.configure(
      appModule: PassengerDependencies(prefs: prefs),
      initialRoute: HomeRoutes.fullHomePath,
      debugLogDiagnostics: true,
      debugLogDiagnosticsGoRouter: true,
      debugLogEventBus: true,
    );

    runApp(const PassengerApp());
  } catch (error, stackTrace) {
    runApp(
      SafeClientErrorApp(
        theme: AppTheme.data,
        message: ErrorHandler.getErrorMessage(error, stackTrace),
      ),
    );
  }
}
