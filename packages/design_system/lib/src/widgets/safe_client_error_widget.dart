import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Installs a non-diagnostic framework error surface for both client apps.
///
/// Technical details remain in internal logs while framework error widgets
/// render a stable, presentation-safe message.
void configureClientErrorBoundary({required String appName}) {
  FlutterError.onError = (details) {
    developer.log(
      'Unhandled framework error.',
      name: appName,
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.empty,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    developer.log(
      'Unhandled asynchronous error.',
      name: appName,
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
  ErrorWidget.builder = (_) => const SafeClientErrorWidget();
}

class SafeClientErrorApp extends StatelessWidget {
  final String message;
  final ThemeData theme;

  const SafeClientErrorApp({
    required this.message,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(body: SafeClientErrorWidget(message: message)),
    );
  }
}

class SafeClientErrorWidget extends StatelessWidget {
  final String message;

  const SafeClientErrorWidget({
    this.message = 'Something went wrong. Please try again.',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
