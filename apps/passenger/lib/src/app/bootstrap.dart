import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/app.dart';
import 'package:passenger/src/app/dependencies.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';
import 'package:passenger/src/core/config/env_config.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapApp() async {
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
        BackgroundTelemetry.stopExistingServiceForStartup,
      );
      final preferences = await traceTimelineStage(
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
            options.dsn = EnvConfig.sentryDsn;
            options.tracesSampleRate = 0.1;
            options.environment = EnvConfig.appEnvironment;
          },
          appRunner: () async {
            AppTransitions.configure();

            await traceTimelineStage(
              'passenger.startup.configure_dependencies_and_router',
              () => Modular.configure(
                appModule: AppDependencies(preferences: preferences),
                initialRoute: HomeRoutes.fullHomePath,
                debugLogDiagnostics: true,
                debugLogDiagnosticsGoRouter: true,
                debugLogEventBus: true,
                observers: [appNavigationObserver],
              ),
            );
            developer.Timeline.instantSync(
              'passenger.startup.initial_route_configured',
            );
            await Future<void>.delayed(Duration.zero);

            final nativeService = MapNativeService(
              placeServiceBaseUri: EnvConfig.apiBaseUri,
              dio: Modular.get<Dio>(),
            );
            LocationService.nativeService = nativeService;
            final mapboxToken = EnvConfig.mapboxPublicToken;
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
            runApp(const App());
          },
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Passenger startup failed.',
        name: 'passenger-app',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      captureFirstFrameTiming();
      runApp(
        SafeClientErrorApp(
          theme: AppTheme.main,
          message: ErrorHandler.getErrorMessage(error, stackTrace),
        ),
      );
    }
  } finally {
    startupTask.finish();
  }
}
