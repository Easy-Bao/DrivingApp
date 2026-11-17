import 'dart:developer' as developer;

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:driver/src/app/app.dart';
import 'package:driver/src/app/dependencies.dart';
import 'package:driver/src/core/config/env_config.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/core/telemetry/background_telemetry.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrapApp() async {
  final startupTask = developer.TimelineTask()..start('driver.startup');
  final captureFirstFrameTiming = createFirstFrameTimingRecorder(
    'driver.startup.first_frame',
  );
  var currentStage = 'initializing app';

  try {
    WidgetsFlutterBinding.ensureInitialized();
    configureClientErrorBoundary(appName: 'driver-app');

    try {
      currentStage = 'loading startup configuration';
      final sessionService = SessionStore();
      final stopServiceTask = traceTimelineStage<void>(
        'driver.startup.stop_background_service',
        BackgroundTelemetry.stopExistingServiceForStartup,
      );
      final preferencesTask = traceTimelineStage(
        'driver.startup.load_preferences',
        SharedPreferences.getInstance,
      );
      final sessionTask = traceTimelineStage(
        'driver.startup.restore_session',
        () => _hasSession(sessionService),
      );
      final environmentTask = traceTimelineStage<void>(
        'driver.startup.load_environment',
        () => dotenv.load(fileName: '.env', isOptional: true),
      );

      await Future.wait<void>([
        stopServiceTask,
        preferencesTask.then<void>((_) {}),
        sessionTask.then<void>((_) {}),
        environmentTask,
      ]);
      final preferences = await preferencesTask;
      final hasSession = await sessionTask;

      currentStage = 'initializing crash reporting';
      await traceTimelineStage(
        'driver.startup.sentry_and_app_runner',
        () => SentryFlutter.init(
          (options) {
            options.dsn = EnvConfig.sentryDsn;
            options.tracesSampleRate = 0.1;
            options.environment = EnvConfig.appEnvironment;
          },
          appRunner: () async {
            currentStage = 'configuring dependencies and router';
            await traceTimelineStage(
              'driver.startup.configure_dependencies_and_router',
              () => Modular.configure(
                appModule: AppDependencies(
                  preferences: preferences,
                  sessionService: sessionService,
                ),
                initialRoute: hasSession
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

            currentStage = 'reading API configuration';
            final apiBaseUri = EnvConfig.apiBaseUri;
            final nativeService = MapNativeService(
              placeServiceBaseUri: apiBaseUri,
              dio: Modular.get<Dio>(),
            );
            LocationService.nativeService = nativeService;
            final mapboxToken = EnvConfig.mapboxPublicToken;
            if (mapboxToken == null) {
              debugPrint(
                'Mapbox is disabled because MAPBOX_PUBLIC_TOKEN is missing.',
              );
            }

            currentStage = 'initializing map services';
            await traceTimelineStage(
              'driver.startup.initialize_map_provider',
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
      captureFirstFrameTiming();
      showClientStartupFailure(
        appName: 'driver-app',
        theme: AppTheme.main,
        error: error,
        stackTrace: stackTrace,
        stage: currentStage,
      );
    }
  } finally {
    startupTask.finish();
  }
}

Future<bool> _hasSession(SessionStore sessionService) async {
  try {
    return await sessionService.hasValidSession();
  } catch (_) {
    return false;
  }
}
