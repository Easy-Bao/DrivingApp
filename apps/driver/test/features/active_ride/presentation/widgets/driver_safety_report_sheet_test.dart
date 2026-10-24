import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockRideRepository extends Mock implements RideRepository {}

void main() {
  testWidgets('requires details before submitting a passenger report', (
    tester,
  ) async {
    final repository = _MockRideRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: SafetyReportButton(
            rideId: 'ride-7',
            rideRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();

    expect(find.text('Report a passenger issue'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(ChoiceChip), findsNWidgets(9));
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
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
    final repository = _MockRideRepository();
    when(
      () => repository.createSafetyReport(
        rideId: 'ride-7',
        category: 'non_payment',
        description: 'Passenger did not pay the agreed cash fare.',
      ),
    ).thenAnswer((_) async => const Ok(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: SafetyReportButton(
            rideId: 'ride-7',
            rideRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();
    final reason = find.byKey(const ValueKey('report-reason-non_payment'));
    await tester.ensureVisible(reason);
    await tester.tap(reason);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Passenger did not pay the agreed cash fare.',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    verify(
      () => repository.createSafetyReport(
        rideId: 'ride-7',
        category: 'non_payment',
        description: 'Passenger did not pay the agreed cash fare.',
      ),
    ).called(1);
    expect(find.text('Report a passenger issue'), findsNothing);
    expect(find.text('Report received'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
