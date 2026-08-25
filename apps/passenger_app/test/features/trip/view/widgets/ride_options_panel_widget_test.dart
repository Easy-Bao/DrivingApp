import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_options_panel_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_trip_summary_widget.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  const fareResult = FareResult(
    baseFare: 20,
    distanceCharge: 5,
    timeCharge: 3.17,
    surgeCharge: 0,
    totalFare: 28.17,
  );

  Widget buildPanel({
    FareResult? result = fareResult,
    bool isLoadingFare = false,
    String? fareError,
    VoidCallback? onRetryFare,
    ValueChanged<int>? onTipSelected,
    String passengerName = 'Avery Cruz',
    String? offeredFare,
    double? totalFare,
  }) {
    final customFareController = TextEditingController(
      text: offeredFare ?? result?.totalFare.toStringAsFixed(2) ?? '',
    );
    final notesController = TextEditingController();
    return MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: RideOptionsPanelWidget(
          passengerName: passengerName,
          pickupLabel: 'Current location',
          destinationName: 'Central Park',
          destinationAddress: '123 Main Street',
          fareResult: result,
          onBookPressed: () {},
          customFareController: customFareController,
          customFareError: null,
          isLoadingFare: isLoadingFare,
          fareError: fareError,
          onRetryFare: onRetryFare,
          onCustomFareChanged: (_) {},
          notesController: notesController,
          onNotesChanged: (_) {},
          selectedTipAmount: 0,
          onTipSelected: onTipSelected ?? (_) {},
          totalFare: totalFare ?? result?.totalFare ?? 0,
        ),
      ),
    );
  }

  testWidgets('shows a calm fare loading state without an offer editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(result: null, isLoadingFare: true));

    expect(find.text('Calculating your fare…'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Solo Ride'), findsNothing);
  });

  testWidgets('shows a recoverable fare error without exposing providers', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(
      buildPanel(
        result: null,
        fareError: 'We couldn’t calculate a fare for this route.',
        onRetryFare: () => retryCount++,
      ),
    );

    expect(
      find.text('We couldn’t calculate a fare for this route.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('server'), findsNothing);

    await tester.tap(find.text('Try again'));
    expect(retryCount, 1);
  });

  testWidgets('removes the redundant solo card and visible route statistics', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.text('Trip Details'), findsOneWidget);
    expect(find.text('Current location'), findsOneWidget);
    expect(find.text('Central Park'), findsOneWidget);
    expect(find.text('Calculated fare'), findsNothing);
    expect(find.text('Set your offer'), findsOneWidget);
    expect(find.text('Book directly'), findsOneWidget);
    expect(find.text('Solo Ride'), findsNothing);
    expect(find.text('4.2 km'), findsNothing);
    expect(find.text('12 min'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('opens a custom offer panel from the left and saves the offer', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    await tester.tap(find.byKey(const ValueKey('custom-offer-trigger')));
    await tester.pumpAndSettle();

    expect(find.text('Set your offer'), findsOneWidget);
    expect(find.text('Calculated minimum'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-offer-label')), findsOneWidget);
    expect(find.text('Use calculated fare'), findsNothing);
    expect(find.byKey(const ValueKey('custom-offer-input')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-offer-input')),
      '40.00',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('custom-offer-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom-offer-input')), findsNothing);
    expect(find.text('Your offer: ₱40'), findsOneWidget);
  });

  testWidgets('opens a dedicated trip note editor instead of an inline field', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('trip-note-trigger')));
    await tester.pumpAndSettle();

    final noteInput = find.byKey(const ValueKey('trip-note-input'));
    expect(noteInput, findsOneWidget);
    await tester.enterText(noteInput, 'Meet me at the side entrance.');
    await tester.tap(find.byKey(const ValueKey('trip-note-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trip-note-input')), findsNothing);
    expect(find.text('Note added'), findsOneWidget);
  });

  testWidgets('shows a dynamic passenger and transparent fare calculation', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(offeredFare: '35.00', totalFare: 35));

    final fareSummary = find.byKey(const ValueKey('fare-summary'));
    await tester.ensureVisible(fareSummary);
    await tester.tap(fareSummary);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fare-details')), findsOneWidget);
    expect(find.text('Fare details'), findsOneWidget);
    expect(find.text('Avery Cruz'), findsOneWidget);
    expect(find.text('Base fare'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Calculated fare'), findsOneWidget);
    expect(find.text('Custom offer adjustment'), findsOneWidget);
    expect(find.text('+₱7'), findsOneWidget);
    expect(find.text('No tip added'), findsOneWidget);
    expect(find.text('Pickup'), findsNothing);
    expect(find.text('Destination'), findsNothing);
    expect(find.text('Not now'), findsNothing);
    expect(
      tester.widget<Padding>(find.byKey(const ValueKey('fare-details'))),
      isA<Padding>(),
    );

    await tester.tap(find.byTooltip('Back to trip summary'));
    await tester.pumpAndSettle();
    expect(find.text('Trip Details'), findsOneWidget);
  });

  testWidgets('selects a tip from the summary', (tester) async {
    var selectedTip = 0;
    await tester.pumpWidget(
      buildPanel(onTipSelected: (amount) => selectedTip = amount),
    );

    await tester.tap(find.text('₱20'));
    expect(selectedTip, 20);
    expect(find.text('No tip'), findsOneWidget);
  });

  testWidgets('wraps a long destination address without a layout exception', (
    tester,
  ) async {
    const longAddress =
        '1390 Pear Avenue, Mountain View, California 94043, United States of America';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: RideTripSummaryWidget(
                pickupLabel: 'Mountain View',
                destinationName: 'Silicon Valley Corporate Catering',
                destinationAddress: longAddress,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(longAddress), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-route-dashes')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
