import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('SafeClientErrorView renders title and specific message', (
    tester,
  ) async {
    await tester.pumpWidget(
      SafeClientErrorApp(
        theme: ThemeData(),
        title: 'App configuration error',
        message: 'API_BASE_URL is required.',
      ),
    );

    expect(find.text('App configuration error'), findsOneWidget);
    expect(find.text('API_BASE_URL is required.'), findsOneWidget);
  });

  testWidgets('SafeClientErrorView renders safely without Directionality', (
    tester,
  ) async {
    await tester.pumpWidget(
      const SafeClientErrorView(
        title: 'Widget build error',
        message: 'Missing provider',
      ),
    );

    expect(find.text('Widget build error'), findsOneWidget);
    expect(find.text('Missing provider'), findsOneWidget);
  });

  test(
    'resolveStartupErrorPresentation surfaces configuration and stage errors',
    () {
      final configError = resolveStartupErrorPresentation(
        error: const ConfigurationException(
          'API_BASE_URL is required, and no .env entries were loaded.',
        ),
        stackTrace: StackTrace.empty,
        stage: 'reading API configuration',
        includeDebugDetails: false,
      );
      expect(configError.title, 'App configuration error');
      expect(configError.message, contains('API_BASE_URL is required'));

      final releaseStageError = resolveStartupErrorPresentation(
        error: StateError('secret internal path'),
        stackTrace: StackTrace.empty,
        stage: 'initializing map services',
        includeDebugDetails: false,
      );
      expect(
        releaseStageError.title,
        'Startup failed (initializing map services)',
      );
      expect(
        releaseStageError.message,
        'Failed while initializing map services (StateError). '
        'Try reopening the app.',
      );
      expect(
        releaseStageError.message,
        isNot(contains('secret internal path')),
      );

      final debugStageError = resolveStartupErrorPresentation(
        error: StateError('missing mapbox plugin'),
        stackTrace: StackTrace.empty,
        stage: 'initializing map services',
        includeDebugDetails: true,
      );
      expect(
        debugStageError.message,
        contains('Failed while initializing map services:'),
      );
      expect(debugStageError.message, contains('missing mapbox plugin'));
    },
  );

  testWidgets('configureClientErrorBoundary surfaces widget error context', (
    tester,
  ) async {
    final previousOnError = FlutterError.onError;
    final previousErrorWidgetBuilder = ErrorWidget.builder;
    addTearDown(() {
      FlutterError.onError = previousOnError;
      ErrorWidget.builder = previousErrorWidgetBuilder;
    });

    configureClientErrorBoundary(appName: 'test-app');
    final built = ErrorWidget.builder(
      FlutterErrorDetails(exception: StateError('bad layout state')),
    );

    await tester.pumpWidget(built);

    expect(find.byType(SafeClientErrorView), findsOneWidget);
    expect(find.textContaining('Something went wrong'), findsNothing);
    expect(find.textContaining('bad layout state'), findsOneWidget);
  });

  testWidgets('AppRetryErrorView surfaces title, message, and retry callback', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRetryErrorView(
            title: 'Connection error',
            message: 'Cannot reach the server. Check that the server is running and try again.',
            actionLabel: 'Retry activity',
            onRetry: () => retried++,
          ),
        ),
      ),
    );

    expect(find.text('Connection error'), findsOneWidget);
    expect(
      find.text(
        'Cannot reach the server. Check that the server is running and try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry activity'));
    expect(retried, 1);
  });
}
