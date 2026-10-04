import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverRideRepository extends Mock implements DriverRideRepository {}

void main() {
  testWidgets('requires details before submitting a passenger report', (
    tester,
  ) async {
    final repository = _MockDriverRideRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverSafetyReportButton(
            rideId: 'ride-7',
            rideRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();

    expect(find.text('Report a passenger issue'), findsOneWidget);
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
    final repository = _MockDriverRideRepository();
    when(
      () => repository.createSafetyReport(
        rideId: 'ride-7',
        category: 'non_payment',
        description: 'Passenger did not pay the agreed cash fare.',
      ),
    ).thenAnswer((_) async => const Ok(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: DriverSafetyReportButton(
            rideId: 'ride-7',
            rideRepository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Report a safety issue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash not paid').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Passenger did not pay the agreed cash fare.',
    );
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
    await tester.pump(const Duration(seconds: 3));
  });
}
