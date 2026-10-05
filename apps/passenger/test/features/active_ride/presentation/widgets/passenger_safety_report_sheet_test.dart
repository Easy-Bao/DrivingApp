import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/passenger_safety_report_sheet.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  testWidgets('requires details before submitting a driver report', (
    tester,
  ) async {
    final repository = _MockTrackRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: PassengerSafetyReportButton(
            rideId: 'ride-7',
            trackRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();

    expect(find.text('Report a driver issue'), findsOneWidget);
    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.showDragHandle, isFalse);
    expect(bottomSheet.enableDrag, isTrue);
    expect(find.byIcon(LucideIcons.x), findsNothing);
    expect(find.byIcon(LucideIcons.send), findsNothing);

    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(
      find.text('Choose a reason and describe what happened.'),
      findsOneWidget,
    );
    verifyNever(
      () => repository.createSafetyReport(
        rideId: any(named: 'rideId'),
        category: any(named: 'category'),
        description: any(named: 'description'),
      ),
    );
  });

  testWidgets('submits the selected category and description', (tester) async {
    final repository = _MockTrackRepository();
    when(
      () => repository.createSafetyReport(
        rideId: 'ride-7',
        category: 'unsafe_driving',
        description: 'The driver was driving dangerously near the market.',
      ),
    ).thenAnswer((_) async => const Ok(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: PassengerSafetyReportButton(
            rideId: 'ride-7',
            trackRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unsafe driving').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'The driver was driving dangerously near the market.',
    );
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    verify(
      () => repository.createSafetyReport(
        rideId: 'ride-7',
        category: 'unsafe_driving',
        description: 'The driver was driving dangerously near the market.',
      ),
    ).called(1);
    expect(find.text('Report a driver issue'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('dismisses when the modal barrier is tapped', (tester) async {
    final repository = _MockTrackRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: PassengerSafetyReportButton(
            rideId: 'ride-7',
            trackRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();
    expect(find.text('Report a driver issue'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text('Report a driver issue'), findsNothing);
  });
}
