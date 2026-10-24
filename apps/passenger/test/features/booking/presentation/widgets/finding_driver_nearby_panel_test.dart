import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_nearby_panel.dart';

const _driver = Driver(
  id: '1',
  name: 'Nearby driver',
  vehicleType: 'Tricycle',
  plateNumber: 'ABC 123',
  rating: 4.8,
  lat: 14.6,
  lng: 120.9,
  distanceKm: 0.3,
  etaMinutes: 2,
  score: 1,
);
const _offer = BookingOffer(
  offerId: 'offer',
  sessionId: 'session',
  driverId: '1',
  driverName: 'Nearby driver',
  vehicleType: 'Tricycle',
  plateNumber: 'ABC 123',
  status: 'pending',
  proposedFareAmount: 2788,
);

Future<void> _pump(
  WidgetTester tester, {
  NearbyDriversState availability = const NearbyDriversState(
    drivers: [_driver],
    hasLoaded: true,
  ),
  List<BookingOffer> offers = const [],
  ValueChanged<BookingOffer>? onChoose,
  double scale = 1,
  bool isChoosingDriver = false,
  ValueChanged<Driver>? onSelectDriver,
  String? acceptingOfferId,
  Driver? requestedDriver,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.main,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FindingDriverNearbyPanel(
            availability: availability,
            requestedDriver: requestedDriver,
            offers: offers,
            fare: 27.88,
            onRetry: () {},
            isChoosingDriver: isChoosingDriver,
            onSelectDriver: onSelectDriver ?? (_) {},
            onAcceptOfferPressed: onChoose ?? (_) {},
            onCancelPressed: () {},
            acceptingOfferId: acceptingOfferId,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('loading does not claim zero drivers or an active request', (
    tester,
  ) async {
    await _pump(
      tester,
      isChoosingDriver: true,
      availability: const NearbyDriversState(isLoading: true),
    );
    expect(find.text('Nearby drivers (0)'), findsNothing);
    expect(find.text('Looking nearby'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nearby-drivers-loading')),
      findsOneWidget,
    );
    expect(find.text('Back to trip'), findsOneWidget);
    expect(find.text('Cancel request'), findsNothing);
  });

  testWidgets(
    'empty discovery keeps searching and hides unavailable request actions',
    (tester) async {
      await _pump(
        tester,
        isChoosingDriver: true,
        availability: const NearbyDriversState(hasLoaded: true),
      );
      expect(
        find.byKey(const ValueKey('nearby-drivers-loading')),
        findsOneWidget,
      );
      expect(find.text('Looking nearby'), findsOneWidget);
      expect(find.text('Request driver'), findsNothing);
      expect(
        find.text('No drivers available yet. We’ll keep checking nearby.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'driver choices replace the ongoing empty search when availability changes',
    (tester) async {
      await _pump(
        tester,
        isChoosingDriver: true,
        availability: const NearbyDriversState(hasLoaded: true),
      );
      expect(
        find.byKey(const ValueKey('nearby-drivers-loading')),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Back to trip'), findsOneWidget);
      await _pump(tester, isChoosingDriver: true);
      expect(
        find.byKey(const ValueKey('nearby-drivers-loading')),
        findsNothing,
      );
      expect(find.text('Nearby driver'), findsOneWidget);
      expect(find.text('Request driver'), findsOneWidget);
    },
  );

  testWidgets(
    'shows available drivers in one container before anyone accepts',
    (tester) async {
      Driver? selected;
      await _pump(
        tester,
        isChoosingDriver: true,
        onSelectDriver: (driver) => selected = driver,
      );
      expect(
        find.byKey(const ValueKey('finding-driver-nearby-panel')),
        findsOneWidget,
      );
      expect(find.text('Nearby drivers'), findsOneWidget);
      expect(find.text('Nearby driver'), findsOneWidget);
      await tester.tap(find.text('Nearby driver'));
      expect(selected, isNull);
      await tester.pump();
      await tester.ensureVisible(find.text('Request driver'));
      await tester.tap(find.text('Request driver'));
      expect(selected, same(_driver));
      expect(find.text('Choose driver'), findsNothing);
      expect(find.text('₱27.88'), findsOneWidget);
    },
  );

  testWidgets(
    'waiting names only the requested driver and uses a visible cancel action',
    (tester) async {
      await _pump(tester, requestedDriver: _driver);
      expect(find.text('Waiting for driver'), findsOneWidget);
      expect(
        find.text('Your request was sent. Waiting for the driver to accept.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Refresh nearby drivers'), findsNothing);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Cancel request'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'driver selection needs an explicit request and prevents duplicate sends',
    (tester) async {
      var requests = 0;
      await _pump(
        tester,
        isChoosingDriver: true,
        onSelectDriver: (_) => requests++,
      );
      expect(find.byTooltip('Refresh nearby drivers'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Request driver'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Nearby driver'));
      await tester.pump();
      expect(requests, 0);
      await tester.ensureVisible(find.text('Request driver'));
      await tester.tap(find.text('Request driver'));
      await tester.pump();
      await tester.tap(find.text('Sending request…'));
      expect(requests, 1);
    },
  );

  testWidgets('adds a choose action to the same row after fare acceptance', (
    tester,
  ) async {
    BookingOffer? chosen;
    await _pump(tester, offers: [_offer], onChoose: (offer) => chosen = offer);
    expect(find.text('Waiting for driver'), findsOneWidget);
    expect(find.text('Nearby driver'), findsOneWidget);
    expect(find.text('Accepted fare · ₱27.88'), findsOneWidget);
    await tester.tap(find.text('Choose driver'));
    expect(chosen, same(_offer));
  });

  testWidgets('retains an actionable response when availability lookup fails', (
    tester,
  ) async {
    await _pump(
      tester,
      availability: const NearbyDriversState(errorMessage: 'Unavailable'),
      offers: [_offer],
    );
    expect(find.byKey(const ValueKey('nearby-drivers-error')), findsOneWidget);
    expect(find.text('Nearby driver'), findsOneWidget);
    expect(find.text('Choose driver'), findsOneWidget);
  });

  testWidgets('keeps the list scrollable with large text on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, offers: [_offer], scale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Choose driver'), 100);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Cancel request'), 100);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks another choice while confirmation is in flight', (
    tester,
  ) async {
    var selections = 0;
    await _pump(
      tester,
      offers: [_offer],
      acceptingOfferId: 'offer',
      onChoose: (_) => selections++,
    );
    await tester.tap(find.text('Confirming…'));
    expect(selections, 0);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Cancel request'),
          )
          .onPressed,
      isNull,
    );
  });
}
