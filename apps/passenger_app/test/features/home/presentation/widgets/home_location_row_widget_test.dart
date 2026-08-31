import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/presentation/widgets/home_location_row_widget.dart';

void main() {
  testWidgets('shows address lookup progress when location access is ready', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeLocationRowWidget(
            isAccessChecking: false,
            hasLocationAccess: true,
            isAddressLoading: false,
            currentAddress: '',
            onRequestLocation: () {},
            onRetryAddress: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('Finding your pickup location…'), findsOneWidget);
    expect(find.text('Turn on location to set pickup'), findsNothing);

    await tester.tap(find.byType(HomeLocationRowWidget));
    expect(retryCount, 1);
  });

  testWidgets('shows and retries a pickup location failure', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeLocationRowWidget(
            isAccessChecking: false,
            hasLocationAccess: true,
            isAddressLoading: false,
            currentAddress: '',
            locationErrorMessage: 'Unable to find your pickup location.',
            onRequestLocation: () {},
            onRetryAddress: () => retryCount++,
          ),
        ),
      ),
    );

    expect(find.text('Unable to find your pickup location.'), findsOneWidget);
    await tester.tap(find.byType(HomeLocationRowWidget));
    expect(retryCount, 1);
  });

  testWidgets('requests location access only when access is unavailable', (
    tester,
  ) async {
    var requestCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeLocationRowWidget(
            isAccessChecking: false,
            hasLocationAccess: false,
            isAddressLoading: false,
            currentAddress: '',
            onRequestLocation: () => requestCount++,
            onRetryAddress: () {},
          ),
        ),
      ),
    );

    expect(find.text('Turn on location to set pickup'), findsOneWidget);

    await tester.tap(find.byType(HomeLocationRowWidget));
    expect(requestCount, 1);
  });
}
