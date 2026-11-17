import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Registers a one-shot callback that logs first-frame build and raster
/// durations to the developer timeline under [timelineEventName].
VoidCallback createFirstFrameTimingRecorder(String timelineEventName) {
  var registered = false;
  return () {
    if (registered) return;
    registered = true;

    late final TimingsCallback callback;
    callback = (timings) {
      if (timings.isEmpty) return;
      WidgetsBinding.instance.removeTimingsCallback(callback);
      final timing = timings.first;
      developer.Timeline.instantSync(
        timelineEventName,
        arguments: {
          'build_duration_us': timing.buildDuration.inMicroseconds,
          'raster_duration_us': timing.rasterDuration.inMicroseconds,
        },
      );
    };
    WidgetsBinding.instance.addTimingsCallback(callback);
  };
}

/// Technical details remain in internal logs while framework error widgets
/// render an actionable, presentation-safe message.
void configureClientErrorBoundary({required String appName}) {
  FlutterError.onError = (details) {
    // Keep framework diagnostics visible in the debug console.
    if (kDebugMode) FlutterError.presentError(details);
    developer.log(
      'Unhandled framework error.',
      name: appName,
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.empty,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[$appName] Unhandled asynchronous error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    developer.log(
      'Unhandled asynchronous error.',
      name: appName,
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
  ErrorWidget.builder = (details) {
    if (kDebugMode) {
      return SafeClientErrorView(
        title: 'Widget build error',
        message: details.exceptionAsString(),
      );
    }
    return SafeClientErrorView(
      title: 'Display error',
      message:
          'This section could not be rendered (${details.exception.runtimeType}).',
    );
  };
}

/// Resolves a startup failure into a specific title and message without leaking
/// arbitrary runtime internals in release builds.
({String title, String message}) resolveStartupErrorPresentation({
  required Object error,
  required StackTrace stackTrace,
  String? stage,
  bool includeDebugDetails = kDebugMode,
}) {
  final failure = ErrorHandler.getAppFailure(error, stackTrace);
  if (failure.type != ErrorType.unknown) {
    return (
      title: failure.title ?? 'Startup failed',
      message: failure.userMessage,
    );
  }

  final step = stage == null ? 'during startup' : 'while $stage';
  return (
    title: stage == null ? 'Startup failed' : 'Startup failed ($stage)',
    message: includeDebugDetails
        ? 'Failed $step: $error'
        : 'Failed $step (${error.runtimeType}). Try reopening the app.',
  );
}

/// Logs a client startup failure and replaces the root widget with a clear,
/// non-vague error surface.
void showClientStartupFailure({
  required String appName,
  required ThemeData theme,
  required Object error,
  required StackTrace stackTrace,
  String? stage,
}) {
  final stageLabel = stage == null ? '' : ' during $stage';
  developer.log(
    '$appName startup failed$stageLabel.',
    name: appName,
    error: error,
    stackTrace: stackTrace,
    level: 1000,
  );
  if (kDebugMode) {
    debugPrint('[$appName] Startup failed$stageLabel: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final presentation = resolveStartupErrorPresentation(
    error: error,
    stackTrace: stackTrace,
    stage: stage,
  );
  runApp(
    SafeClientErrorApp(
      theme: theme,
      title: presentation.title,
      message: presentation.message,
    ),
  );
}

class const SafeClientErrorApp({
  required this.message,
  required this.theme,
  this.title,
  super.key,
}) extends StatelessWidget {
  final String? title;
  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: SafeClientErrorView(title: title, message: message),
      ),
    );
  }
}

class const SafeClientErrorView({
  this.title,
  this.message = 'This section could not be displayed. Try again.',
  super.key,
}) extends StatelessWidget {
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final content = Material(
      color: colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (Directionality.maybeOf(context) != null) return content;
    return Directionality(textDirection: TextDirection.ltr, child: content);
  }
}

typedef SafeClientErrorWidget = SafeClientErrorView;
