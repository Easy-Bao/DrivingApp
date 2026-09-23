import 'package:design_system/design_system.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver/src/features/earnings/presentation/view/earnings_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeEarningsRepository implements DriverEarningsRepository {
  @override
  Future<Result<Map<String, dynamic>, Failure>> fetchEarningsSummary(
    String driverId,
  ) async {
    return const Ok({
      'today': {'earnings_amount': 2973, 'completed_trips': 1},
      'this_week': {'earnings_amount': 2973, 'completed_trips': 1},
      'this_month': {'earnings_amount': 2973, 'completed_trips': 1},
      'weekdays': [
        {'start_date': '2026-08-17', 'earnings_amount': 2973},
        {'start_date': '2026-08-18', 'earnings_amount': 0},
        {'start_date': '2026-08-19', 'earnings_amount': 0},
        {'start_date': '2026-08-20', 'earnings_amount': 0},
        {'start_date': '2026-08-21', 'earnings_amount': 0},
        {'start_date': '2026-08-22', 'earnings_amount': 0},
        {'start_date': '2026-08-23', 'earnings_amount': 0},
      ],
      'month_weeks': [
        {'start_date': '2026-08-01', 'earnings_amount': 2973},
        {'start_date': '2026-08-08', 'earnings_amount': 0},
        {'start_date': '2026-08-15', 'earnings_amount': 0},
        {'start_date': '2026-08-22', 'earnings_amount': 0},
        {'start_date': '2026-08-29', 'earnings_amount': 0},
      ],
    });
  }
}

void main() {
  late DriverSessionStore sessionService;

  setUp(() {
    final storage = _MockSecureStorage();
    when(
      () => storage.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'driver-1');

    sessionService = DriverSessionStore(storage: storage);
  });

  testWidgets('period tabs stay within a compact driver layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: BlocProvider(
          create: (_) => DriverEarningsCubit(
            repository: _FakeEarningsRepository(),
            sessionService: sessionService,
          )..load(),
          child: const DriverEarningsPage(),
        ),
      ),
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

  testWidgets(
    'formats negative adjustments and fee deductions with distinct cues',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: BlocProvider(
            create: (_) => DriverEarningsCubit(
              repository: _FakeNegativeEarningsRepository(),
              sessionService: sessionService,
            )..load(),
            child: const DriverEarningsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-₱50'), findsWidgets);
      expect(find.text('Adjustment'), findsOneWidget);
      expect(
        find.text('Fee deductions or dispute adjustments applied'),
        findsOneWidget,
      );

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final firstRod = barChart.data.barGroups.first.barRods.first;
      expect(firstRod.label.text, '-₱50');
    },
  );
}

class _FakeNegativeEarningsRepository implements DriverEarningsRepository {
  @override
  Future<Result<Map<String, dynamic>, Failure>> fetchEarningsSummary(
    String driverId,
  ) async {
    return const Ok({
      'today': {'earnings_amount': -5000, 'completed_trips': 1},
      'this_week': {'earnings_amount': -5000, 'completed_trips': 1},
      'this_month': {'earnings_amount': -5000, 'completed_trips': 1},
      'weekdays': [
        {'start_date': '2026-08-17', 'earnings_amount': -5000},
        {'start_date': '2026-08-18', 'earnings_amount': 0},
        {'start_date': '2026-08-19', 'earnings_amount': 0},
        {'start_date': '2026-08-20', 'earnings_amount': 0},
        {'start_date': '2026-08-21', 'earnings_amount': 0},
        {'start_date': '2026-08-22', 'earnings_amount': 0},
        {'start_date': '2026-08-23', 'earnings_amount': 0},
      ],
      'month_weeks': [
        {'start_date': '2026-08-01', 'earnings_amount': -5000},
        {'start_date': '2026-08-08', 'earnings_amount': 0},
        {'start_date': '2026-08-15', 'earnings_amount': 0},
        {'start_date': '2026-08-22', 'earnings_amount': 0},
        {'start_date': '2026-08-29', 'earnings_amount': 0},
      ],
    });
  }
}
