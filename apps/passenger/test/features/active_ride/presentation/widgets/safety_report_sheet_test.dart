import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/safety_report_sheet.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

Future<void> _openSheet(
  WidgetTester tester,
  TrackRepository repository, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.main,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SafetyReportButton(
          rideId: 'ride-7',
          driverName: 'Alex Driver',
          vehiclePlate: 'ABC 2034',
          vehicleType: 'Tricycle',
          trackRepository: repository,
        ),
      ),
    ),
  );
  await tester.tap(find.byTooltip('Report a safety issue'));
  await tester.pumpAndSettle();
}

Future<void> _completeForm(WidgetTester tester) async {
  final reason = find.byKey(const ValueKey('report-reason-unsafe_driving'));
  await tester.ensureVisible(reason);
  await tester.tap(reason);
  await tester.enterText(
    find.byType(TextField),
    'The driver was driving dangerously near the market.',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows trip details and requires a reason and nonblank details', (
    tester,
  ) async {
    final repository = _MockTrackRepository();
    await _openSheet(tester, repository);

    expect(find.text('Report a driver issue'), findsOneWidget);
    expect(find.text('Alex Driver'), findsOneWidget);
    expect(find.text('ABC 2034 | Tricycle'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(10));
    expect(find.byIcon(LucideIcons.x), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.textContaining('private from'), findsNothing);
    expect(find.textContaining('timeline'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.showDragHandle, isTrue);
    expect(sheet.enableDrag, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('report-reason-unsafe_driving')),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    verifyNever(
      () => repository.createSafetyReport(
        rideId: any(named: 'rideId'),
        category: any(named: 'category'),
        description: any(named: 'description'),
      ),
    );
  });

  testWidgets('report form does not repeat the receipt reference', (
    tester,
  ) async {
    await _openSheet(tester, _MockTrackRepository());
    expect(find.textContaining('Booking ID'), findsNothing);
    expect(find.byTooltip('Copy Booking ID'), findsNothing);
  });

  testWidgets(
    'submits the selected category and description once with feedback',
    (tester) async {
      final repository = _MockTrackRepository();
      final pending = Completer<Result<void, Failure>>();
      when(
        () => repository.createSafetyReport(
          rideId: 'ride-7',
          category: 'unsafe_driving',
          description: 'The driver was driving dangerously near the market.',
        ),
      ).thenAnswer((_) => pending.future);
      await _openSheet(tester, repository);
      await _completeForm(tester);
      await tester.tap(find.text('Submit report'));
      await tester.pump();
      expect(find.text('Submitting…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.complete(const Ok(null));
      await tester.pumpAndSettle();
      verify(
        () => repository.createSafetyReport(
          rideId: 'ride-7',
          category: 'unsafe_driving',
          description: 'The driver was driving dangerously near the market.',
        ),
      ).called(1);
      expect(find.text('Report a driver issue'), findsNothing);
      expect(find.text('Report received'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Submit report'), findsNothing);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('keeps the draft and allows retry after a failed submission', (
    tester,
  ) async {
    final repository = _MockTrackRepository();
    when(
      () => repository.createSafetyReport(
        rideId: any(named: 'rideId'),
        category: any(named: 'category'),
        description: any(named: 'description'),
      ),
    ).thenAnswer(
      (_) async => const Err(NetworkFailure('Unable to submit. Try again.')),
    );
    await _openSheet(tester, repository);
    await _completeForm(tester);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to submit. Try again.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'The driver was driving dangerously near the market.',
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('report-reason-unsafe_driving')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('dismisses when the blank area outside the sheet is tapped', (
    tester,
  ) async {
    await _openSheet(tester, _MockTrackRepository());
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Report a driver issue'), findsNothing);
  });

  testWidgets('dismisses when the drag handle is pulled down', (tester) async {
    await _openSheet(tester, _MockTrackRepository());
    final sheetBounds = tester.getRect(find.byType(BottomSheet));
    await tester.dragFrom(
      Offset(sheetBounds.center.dx, sheetBounds.top + 20),
      const Offset(0, 700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Report a driver issue'), findsNothing);
  });

  testWidgets(
    'scrolls on a narrow screen with large text and a keyboard inset',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await _openSheet(tester, _MockTrackRepository(), textScale: 1.8);
      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(FilledButton)).bottom,
        lessThanOrEqualTo(380),
      );
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
