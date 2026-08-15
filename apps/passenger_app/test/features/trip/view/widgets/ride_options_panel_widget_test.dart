import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_options_panel_widget.dart';

void main() {
  Widget buildPanel({
    List<RideOptionData> options = const [],
    bool isLoadingFare = false,
    String? fareError,
    VoidCallback? onRetryFare,
    ValueChanged<int>? onTipSelected,
    VoidCallback? onShowFareDetails,
    VoidCallback? onHideFareDetails,
    bool isShowingFareDetails = false,
  }) {
    final customFareController = TextEditingController(
      text: options.isEmpty ? '' : '35.00',
    );
    return MaterialApp(
      home: Scaffold(
        body: RideOptionsPanelWidget(
          rideTypeLabel: 'Solo Ride',
          pickupLabel: 'Current location',
          destinationName: 'Central Park',
          destinationAddress: '123 Main Street',
          distance: '4.2 km',
          duration: '12 min',
          options: options,
          selectedIndex: 0,
          onOptionSelected: (_) {},
          onBookPressed: () {},
          customFareController: customFareController,
          minimumFare: options.isEmpty ? null : 35,
          customFareError: null,
          isLoadingFare: isLoadingFare,
          fareError: fareError,
          onRetryFare: onRetryFare,
          onCustomFareChanged: (_) {},
          notesController: TextEditingController(),
          onNotesChanged: (_) {},
          selectedTipAmount: 0,
          onTipSelected: onTipSelected ?? (_) {},
          totalFare: 35,
          isShowingFareDetails: isShowingFareDetails,
          onShowFareDetails: onShowFareDetails ?? () {},
          onHideFareDetails: onHideFareDetails ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows a neutral fare loading state', (tester) async {
    await tester.pumpWidget(buildPanel(isLoadingFare: true));

    expect(find.text('Calculating fare…'), findsNWidgets(2));
    expect(find.textContaining('server'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows a recoverable fare error without exposing providers', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(
      buildPanel(
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

  testWidgets('shows the offer controls after fare calculation succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPanel(
        options: const [
          RideOptionData(
            name: 'Solo Ride',
            subtitle: 'Private ride with a calculated minimum fare',
            icon: Icons.directions_car,
            fare: 35,
            eta: 'Estimated for this route',
          ),
        ],
      ),
    );

    expect(find.text('Solo Ride'), findsOneWidget);
    expect(find.text('Your offer'), findsOneWidget);
    expect(find.text('Book Solo Ride'), findsOneWidget);
    expect(find.text('Current location'), findsOneWidget);
    expect(find.text('Central Park'), findsOneWidget);
  });

  testWidgets('selects a tip, accepts notes, and opens fare details', (
    tester,
  ) async {
    var selectedTip = 0;
    var showDetailsCount = 0;
    var hideDetailsCount = 0;
    await tester.pumpWidget(
      buildPanel(
        options: const [
          RideOptionData(
            name: 'Solo Ride',
            subtitle: 'Private ride with a calculated minimum fare',
            icon: Icons.directions_car,
            fare: 35,
            eta: 'Estimated for this route',
          ),
        ],
        onTipSelected: (value) => selectedTip = value,
        onShowFareDetails: () => showDetailsCount++,
        onHideFareDetails: () => hideDetailsCount++,
      ),
    );

    await tester.tap(find.text('₱20'));
    expect(selectedTip, 20);

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), 'Call when you arrive');
    expect(find.text('Notes for the driver (optional)'), findsOneWidget);

    await tester.ensureVisible(find.text('Total fare'));
    await tester.tap(find.text('Total fare'));
    expect(showDetailsCount, 1);

    await tester.pumpWidget(
      buildPanel(
        options: const [
          RideOptionData(
            name: 'Solo Ride',
            subtitle: 'Private ride with a calculated minimum fare',
            icon: Icons.directions_car,
            fare: 35,
            eta: 'Estimated for this route',
          ),
        ],
        isShowingFareDetails: true,
        onHideFareDetails: () => hideDetailsCount++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fare details'), findsOneWidget);
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Pickup'), findsNWidgets(2));
    expect(find.text('Destination'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Back to fare summary'));
    expect(hideDetailsCount, 1);
  });
}
