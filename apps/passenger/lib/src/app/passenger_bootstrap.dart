import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/passenger_navigation_observer.dart';
import 'package:passenger/src/app/passenger_app.dart';
import 'package:passenger/src/app/passenger_dependencies.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/infrastructure/config/passenger_env_config.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapPassengerApp() async {
  final startupTask = developer.TimelineTask()..start('passenger.startup');
  var firstFrameCallbackRegistered = false;

  void captureFirstFrameTiming() {
    if (firstFrameCallbackRegistered) return;
    firstFrameCallbackRegistered = true;

    late final ui.TimingsCallback callback;
    callback = (timings) {
      if (timings.isEmpty) return;
      WidgetsBinding.instance.removeTimingsCallback(callback);
      final timing = timings.first;
      developer.Timeline.instantSync(
        'passenger.startup.first_frame',
        arguments: {
          'build_duration_us': timing.buildDuration.inMicroseconds,
          'raster_duration_us': timing.rasterDuration.inMicroseconds,
        },
      );
    };
    WidgetsBinding.instance.addTimingsCallback(callback);
  }

  try {
    WidgetsFlutterBinding.ensureInitialized();
    configureClientErrorBoundary(appName: 'passenger-app');

    try {
      await traceTimelineStage(
        'passenger.startup.stop_background_service',
        PassengerBackgroundTelemetry.stopExistingServiceForStartup,
      );
      final prefs = await traceTimelineStage(
        'passenger.startup.load_preferences',
        SharedPreferences.getInstance,
      );

      await traceTimelineStage(
        'passenger.startup.load_environment',
        () => dotenv.load(fileName: '.env', isOptional: true),
      );

      await traceTimelineStage(
        'passenger.startup.sentry_and_app_runner',
        () => SentryFlutter.init(
          (options) {
            options.dsn = PassengerEnvConfig.sentryDsn;
            options.tracesSampleRate = 0.1;
            options.environment = PassengerEnvConfig.appEnvironment;
          },
          appRunner: () async {
            AppTransitions.configure();

            await traceTimelineStage(
              'passenger.startup.configure_dependencies_and_router',
              () => Modular.configure(
                appModule: PassengerDependencies(prefs: prefs),
                initialRoute: HomeRoutes.fullHomePath,
                debugLogDiagnostics: true,
                debugLogDiagnosticsGoRouter: true,
                debugLogEventBus: true,
                observers: [passengerNavigationObserver],
              ),
            );
            developer.Timeline.instantSync(
              'passenger.startup.initial_route_configured',
            );
            await Future<void>.delayed(Duration.zero);

            final nativeService = MapNativeService(
              placeServiceBaseUri: PassengerEnvConfig.apiBaseUri,
              dio: Modular.get<Dio>(),
            );
            LocationService.nativeService = nativeService;
            final mapboxToken = PassengerEnvConfig.mapboxPublicToken;
            if (mapboxToken == null) {
              debugPrint(
                'Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.',
              );
            }
            await traceTimelineStage(
              'passenger.startup.initialize_map_provider',
              () => MapProvider.initialize(
                token: mapboxToken,
                nativeService: nativeService,
              ),
            );

            captureFirstFrameTiming();
            runApp(const PassengerApp());
          },
        ),
      );
    } catch (error, stackTrace) {
      captureFirstFrameTiming();
      runApp(
        SafeClientErrorApp(
          theme: EasyRideTheme.main,
          message: ErrorHandler.getErrorMessage(error, stackTrace),
        ),
      );
    }
  } finally {
    startupTask.finish();
  }
}
