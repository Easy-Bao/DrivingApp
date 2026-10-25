import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:driver/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/presentation/view/earnings_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeEarningsRepository implements EarningsRepository {
  @override
  Future<Result<EarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  ) async {
    return Ok(
      EarningsSummary.fromJson(const {
        'today': {'earnings_amount': 2973, 'completed_trips': 1},
        'this_week': {'earnings_amount': 2973, 'completed_trips': 1},
        'this_month': {'earnings_amount': 2973, 'completed_trips': 1},
        'weekdays': [
          {
            'start_date': '2026-08-17',
            'earnings_amount': 2973,
            'completed_trips': 1,
          },
          {'start_date': '2026-08-18', 'earnings_amount': 0},
          {'start_date': '2026-08-19', 'earnings_amount': 0},
          {'start_date': '2026-08-20', 'earnings_amount': 0},
          {'start_date': '2026-08-21', 'earnings_amount': 0},
          {'start_date': '2026-08-22', 'earnings_amount': 0},
          {'start_date': '2026-08-23', 'earnings_amount': 0},
        ],
        'month_weeks': [
          {
            'start_date': '2026-08-01',
            'earnings_amount': 2973,
            'completed_trips': 1,
          },
          {'start_date': '2026-08-08', 'earnings_amount': 0},
          {'start_date': '2026-08-15', 'earnings_amount': 0},
          {'start_date': '2026-08-22', 'earnings_amount': 0},
          {'start_date': '2026-08-29', 'earnings_amount': 0},
        ],
      }),
    );
  }
}

class _PendingEarningsRepository implements EarningsRepository {
  final completer = Completer<Result<EarningsSummary, Failure>>();

  @override
  Future<Result<EarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  ) => completer.future;
}

class _ReloadingEarningsRepository extends _FakeEarningsRepository {
  final reload = Completer<Result<EarningsSummary, Failure>>();
  var _requestCount = 0;

  @override
  Future<Result<EarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  ) {
    if (_requestCount++ == 0) {
      return super.fetchEarningsSummary(driverId);
    }
    return reload.future;
  }
}

void main() {
  late SessionStore sessionService;

  setUp(() {
    final storage = _MockSecureStorage();
    when(
      () => storage.read(
        key: any(named: 'key'),
        aOptions: any(named: 'aOptions'),
      ),
    ).thenAnswer((_) async => 'driver-1');

    sessionService = SessionStore(storage: storage);
  });

  testWidgets('period tabs stay within a compact driver layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider(
          create: (_) => EarningsCubit(
            repository: _FakeEarningsRepository(),
            sessionService: sessionService,
          )..load(),
          child: const EarningsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Completed rides reported by the server'), findsNothing);
    expect(find.text('Drive time'), findsNothing);
    expect(find.text('Driver rating'), findsNothing);
    expect(find.text('Avg per trip'), findsOneWidget);
    final verticalScrollables = find.byWidgetPredicate(
      (widget) => widget is Scrollable && widget.axis == Axis.vertical,
    );
    expect(verticalScrollables, findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'initial layout failed');

    for (final period in ['Day', 'Week', 'Month']) {
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

  testWidgets('shows dated recent earnings and switches period summaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider(
          create: (_) => EarningsCubit(
            repository: _FakeEarningsRepository(),
            sessionService: sessionService,
          )..load(),
          child: const EarningsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This week · Aug 17 – Aug 23'), findsOneWidget);
    expect(find.text('From 1 completed ride'), findsOneWidget);
    expect(find.text('1 of 7'), findsOneWidget);
    expect(find.text('+₱29.73'), findsOneWidget);
    expect(find.text('See all'), findsNothing);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(
      chart.data.barGroups
          .where((group) => group.barRods.first.label.show)
          .length,
      1,
    );
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.text('Active weeks'), findsOneWidget);
    expect(find.text('1 of 5'), findsOneWidget);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Active days'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports large text on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BlocProvider(
          create: (_) => EarningsCubit(
            repository: _FakeEarningsRepository(),
            sessionService: sessionService,
          )..load(),
          child: const EarningsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps loaded earnings visible while refreshing', (tester) async {
    final repository = _ReloadingEarningsRepository();
    late final EarningsCubit cubit;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: BlocProvider(
          create: (_) => cubit = EarningsCubit(
            repository: repository,
            sessionService: sessionService,
          )..load(),
          child: const EarningsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Avg per trip'), findsOneWidget);

    final refresh = cubit.load();
    await tester.pump();

    expect(cubit.state.isLoading, isTrue);
    expect(find.byType(BarChart), findsOneWidget);
    expect(
      tester
          .widgetList<Skeletonizer>(find.byType(Skeletonizer))
          .where((skeletonizer) => skeletonizer.enabled),
      isEmpty,
    );

    repository.reload.complete(
      Ok(
        EarningsSummary.fromJson(const {
          'today': {'earnings_amount': 2973, 'completed_trips': 1},
          'this_week': {'earnings_amount': 2973, 'completed_trips': 1},
          'this_month': {'earnings_amount': 2973, 'completed_trips': 1},
          'weekdays': <Map<String, Object>>[],
          'month_weeks': <Map<String, Object>>[],
        }),
      ),
    );
    await refresh;
    await tester.pumpAndSettle();
  });

  for (final (width, scale) in [(800.0, 1.0), (320.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      'loading layout matches content at width $width and scale $scale',
      (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _PendingEarningsRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: BlocProvider(
              create: (_) => EarningsCubit(
                repository: repository,
                sessionService: sessionService,
              )..load(),
              child: const EarningsPage(),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(
            const ValueKey<String>('driver-earnings-loading-skeleton'),
          ),
          findsOneWidget,
        );
        expect(find.text('Day'), findsOneWidget);
        expect(find.text('Avg per trip'), findsOneWidget);
        expect(find.text('Recent'), findsOneWidget);
        final loadingChart = tester.getRect(find.byType(BarChart));
        final loadingTabs = tester.getRect(find.text('Week'));
        final loadingStats = tester.getRect(find.text('Trips'));
        expect(loadingChart.width, greaterThan(190));
        expect(loadingChart.height, closeTo(190, 0.01));
        await tester.tap(find.text('Day'), warnIfMissed: false);
        await tester.pump();

        repository.completer.complete(
          Ok(
            EarningsSummary.fromJson(const {
              'today': {'earnings_amount': 2973, 'completed_trips': 1},
              'this_week': {'earnings_amount': 2973, 'completed_trips': 1},
              'this_month': {'earnings_amount': 2973, 'completed_trips': 1},
              'weekdays': <Map<String, Object>>[],
              'month_weeks': <Map<String, Object>>[],
            }),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('This week'), findsOneWidget);
        for (final (finder, bounds) in [
          (find.byType(BarChart), loadingChart),
          (find.text('Week'), loadingTabs),
          (find.text('Trips'), loadingStats),
        ]) {
          final loaded = tester.getRect(finder);
          expect(loaded.left, closeTo(bounds.left, 0.01));
          expect(loaded.top, closeTo(bounds.top, 0.01));
          expect(loaded.width, closeTo(bounds.width, 0.01));
          expect(loaded.height, closeTo(bounds.height, 0.01));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'formats negative adjustments and fee deductions with distinct cues',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: BlocProvider(
            create: (_) => EarningsCubit(
              repository: _FakeNegativeEarningsRepository(),
              sessionService: sessionService,
            )..load(),
            child: const EarningsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-₱50.00'), findsWidgets);
      expect(find.text('Adjustment'), findsOneWidget);
      expect(
        find.text('Fee deductions or dispute adjustments applied'),
        findsOneWidget,
      );

      final barChart = tester.widget<BarChart>(find.byType(BarChart));
      final firstRod = barChart.data.barGroups.first.barRods.first;
      expect(firstRod.label.text, '-₱50.00');
    },
  );
}

class _FakeNegativeEarningsRepository implements EarningsRepository {
  @override
  Future<Result<EarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  ) async {
    return Ok(
      EarningsSummary.fromJson(const {
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
      }),
    );
  }
}
