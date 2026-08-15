import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_options_panel_widget.dart';

void main() {
  Widget buildPanel({
    List<RideOptionData> options = const [],
    bool isLoadingFare = false,
    String? fareError,
    VoidCallback? onRetryFare,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RideOptionsPanelWidget(
          options: options,
          selectedIndex: 0,
          onOptionSelected: (_) {},
          onBookPressed: () {},
          customFareController: TextEditingController(),
          minimumFare: options.isEmpty ? null : 35,
          customFareError: null,
          isLoadingFare: isLoadingFare,
          fareError: fareError,
          onRetryFare: onRetryFare,
          onCustomFareChanged: (_) {},
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
  });
}
