import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/view/earnings_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router_modular/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeActivityRepository implements IDriverActivityRepository {
  @override
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId) {
    return Future.value(
      const Right<Failure, List<dynamic>>([
        {
          'status': 'completed',
          'completed_at': '2026-08-19T10:00:00Z',
          'fare_pesos': 29.73,
          'duration_minutes': 6,
        },
      ]),
    );
  }
}

void main() {
  late ModularTestScope scope;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'rating': '5.0'});
    final preferences = await SharedPreferences.getInstance();
    final storage = _MockSecureStorage();
    when(
      () => storage.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'driver-1');

    scope = ModularTestScope.fresh()
        .withInstance<SharedPreferences>(preferences)
        .withInstance<SecureSessionService>(
          SecureSessionService(storage: storage),
        )
        .withInstance<IDriverActivityRepository>(_FakeActivityRepository());
    scope.setUp();
  });

  tearDown(() {
    scope.tearDown();
  });

  testWidgets('period tabs stay within a compact driver layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.themeData, home: const DriverEarningsPage()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Completed rides reported by the server'), findsNothing);
    expect(find.text('Drive time'), findsNothing);
    expect(find.text('Driver rating'), findsNothing);
    expect(find.text('Average per trip'), findsOneWidget);
    final verticalScrollables = find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axis == Axis.vertical,
    );
    expect(verticalScrollables, findsOneWidget);
    final scrollState = tester.state<ScrollableState>(verticalScrollables);
    expect(scrollState.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull, reason: 'initial layout failed');

    for (final period in ['Daily', 'Weekly', 'Monthly']) {
      await tester.tap(find.text(period));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.takeException(),
        isNull,
        reason: '$period initial chart animation frame failed',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: '$period mid chart animation frame failed',
      );
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$period layout failed');
    }
  });
}
