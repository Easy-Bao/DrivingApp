import 'package:maps/maps.dart';
import 'package:driver_app/app_module.dart';
import 'package:driver_app/app_widget.dart';
import 'package:driver_app/src/core/constants/env_config.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/home/home_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureClientErrorBoundary(appName: 'driver-app');

  try {
    await BackgroundTelemetryService.stopExistingServiceForStartup();
    final prefs = await SharedPreferences.getInstance();
    final sessionService = SecureSessionService();
    final hasDriverSession = await _hasDriverSession(sessionService);

    await dotenv.load(fileName: '.env', isOptional: true);

    final nativeService = MapNativeService(
      placeServiceBaseUri: EnvConfig.apiBaseUri,
    );
    LocationService.nativeService = nativeService;
    final mapboxToken = EnvConfig.mapboxPublicToken;
    if (mapboxToken == null) {
      debugPrint('Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.');
    }
    await MapProvider.initialize(
      token: mapboxToken,
      nativeService: nativeService,
    );

    await Modular.configure(
      appModule: AppModule(prefs: prefs, sessionService: sessionService),
      initialRoute: hasDriverSession
          ? HomeRoutes.fullDashboardPath
          : AuthRoutes.signinPath,
      debugLogDiagnostics: true,
      debugLogDiagnosticsGoRouter: true,
      debugLogEventBus: true,
    );

    runApp(const AppWidget());
  } catch (error, stackTrace) {
    runApp(
      SafeClientErrorApp(
        message: ErrorHandler.getErrorMessage(error, stackTrace),
      ),
    );
  }
}

Future<bool> _hasDriverSession(SecureSessionService sessionService) async {
  try {
    return await sessionService.hasValidDriverSession();
  } catch (_) {
    return false;
  }
}
