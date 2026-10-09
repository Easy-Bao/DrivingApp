import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:driver/src/app/driver_app.dart';
import 'package:driver/src/app/driver_dependencies.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/infrastructure/config/driver_env_config.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapDriverApp() async {
  final startupTask = developer.TimelineTask()..start('driver.startup');
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
        'driver.startup.first_frame',
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
    configureClientErrorBoundary(appName: 'driver-app');

    try {
      final sessionService = DriverSessionStore();
      final stopServiceTask = traceTimelineStage<void>(
        'driver.startup.stop_background_service',
        DriverBackgroundTelemetry.stopExistingServiceForStartup,
      );
      final prefsTask = traceTimelineStage(
        'driver.startup.load_preferences',
        SharedPreferences.getInstance,
      );
      final sessionTask = traceTimelineStage(
        'driver.startup.restore_session',
        () => _hasDriverSession(sessionService),
      );
      final environmentTask = traceTimelineStage<void>(
        'driver.startup.load_environment',
        () async {
          await dotenv.load(fileName: '.env', isOptional: true);
        },
      );

      // Finish independent platform and storage work before configuring routes.
      await Future.wait<void>([
        stopServiceTask,
        prefsTask.then<void>((_) {}),
        sessionTask.then<void>((_) {}),
        environmentTask,
      ]);
      final prefs = await prefsTask;
      final hasDriverSession = await sessionTask;

      await traceTimelineStage(
        'driver.startup.sentry_and_app_runner',
        () => SentryFlutter.init(
          (options) {
            options.dsn = DriverEnvConfig.sentryDsn;
            options.tracesSampleRate = 0.1;
            options.environment = DriverEnvConfig.appEnvironment;
          },
          appRunner: () async {
            await traceTimelineStage(
              'driver.startup.configure_dependencies_and_router',
              () => Modular.configure(
                appModule: DriverDependencies(
                  prefs: prefs,
                  sessionService: sessionService,
                ),
                initialRoute: hasDriverSession
                    ? DashboardRoutes.fullDashboardPath
                    : AuthRoutes.signinPath,
                debugLogDiagnostics: true,
                debugLogDiagnosticsGoRouter: true,
                debugLogEventBus: true,
              ),
            );
            developer.Timeline.instantSync(
              'driver.startup.initial_route_configured',
            );
            await Future<void>.delayed(Duration.zero);

            final nativeService = MapNativeService(
              placeServiceBaseUri: DriverEnvConfig.apiBaseUri,
              dio: Modular.get<Dio>(),
            );
            LocationService.nativeService = nativeService;
            final mapboxToken = DriverEnvConfig.mapboxPublicToken;
            if (mapboxToken == null) {
              debugPrint(
                'Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.',
              );
            }
            await traceTimelineStage(
              'driver.startup.initialize_map_provider',
              () => MapProvider.initialize(
                token: mapboxToken,
                nativeService: nativeService,
              ),
            );

            captureFirstFrameTiming();
            runApp(const DriverApp());
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

Future<bool> _hasDriverSession(DriverSessionStore sessionService) async {
  try {
    return await sessionService.hasValidDriverSession();
  } catch (_) {
    return false;
  }
}
