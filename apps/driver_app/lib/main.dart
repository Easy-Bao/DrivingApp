import 'package:maps/maps.dart';
import 'package:driver_app/app_module.dart';
import 'package:driver_app/app_widget.dart';
import 'package:driver_app/src/app/theme/app_theme.dart';
import 'package:driver_app/src/infrastructure/config/driver_env_config.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/auth/auth_routes.dart';
import 'package:driver_app/src/features/home/home_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureClientErrorBoundary(appName: 'driver-app');

  try {
    await DriverBackgroundTelemetry.stopExistingServiceForStartup();
    final prefs = await SharedPreferences.getInstance();
    final sessionService = DriverSessionStore();
    final hasDriverSession = await _hasDriverSession(sessionService);

    await dotenv.load(fileName: '.env', isOptional: true);

    final nativeService = MapNativeService(
      placeServiceBaseUri: DriverEnvConfig.apiBaseUri,
    );
    LocationService.nativeService = nativeService;
    final mapboxToken = DriverEnvConfig.mapboxPublicToken;
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
        theme: AppTheme.data,
        message: ErrorHandler.getErrorMessage(error, stackTrace),
      ),
    );
  }
}

Future<bool> _hasDriverSession(DriverSessionStore sessionService) async {
  try {
    return await sessionService.hasValidDriverSession();
  } catch (_) {
    return false;
  }
}
