import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_options_panel.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_trip_summary.dart';

void main() {
  const fareResult = FareEstimate(
    baseFare: 20,
    distanceCharge: 5,
    timeCharge: 3.17,
    surgeCharge: 0,
    totalFare: 28.17,
  );

  Widget buildPanel({
    FareEstimate? result = fareResult,
    bool isLoadingFare = false,
    String? fareError,
    VoidCallback? onRetryFare,
    int selectedTipAmount = 0,
    ValueChanged<int>? onTipSelected,
    String passengerName = 'Avery Cruz',
    String? offeredFare,
    double? totalFare,
    bool isExpanded = false,
    VoidCallback? onPageBackPressed,
    DraggableScrollableController? sheetController,
    TextEditingController? notesController,
  }) {
    final customFareController = TextEditingController(
      text: offeredFare ?? result?.totalFare.toStringAsFixed(2) ?? '',
    );
    final effectiveNotesController = notesController ?? TextEditingController();

    RideOptionsPanel buildPanelWidget(ScrollController? scrollController) {
      return RideOptionsPanel(
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
        notesController: effectiveNotesController,
        onNotesChanged: (_) {},
        selectedTipAmount: selectedTipAmount,
        onTipSelected: onTipSelected ?? (_) {},
        totalFare: totalFare ?? result?.totalFare ?? 0,
        isExpanded: isExpanded,
        scrollController: scrollController,
        onPageBackPressed: onPageBackPressed,
      );
    }

    final panel = sheetController == null
        ? buildPanelWidget(null)
        : SizedBox.expand(
            child: DraggableScrollableSheet(
              controller: sheetController,
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.34,
              maxChildSize: 1,
              builder: (context, scrollController) =>
                  buildPanelWidget(scrollController),
            ),
          );

    return MaterialApp(
      theme: AppTheme.main,
      home: Scaffold(body: panel),
    );
  }

  testWidgets('shows a loading skeleton without an offer editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(result: null, isLoadingFare: true));

    expect(find.byKey(const ValueKey('ride-options-loading')), findsOneWidget);
    expect(find.text('Trip Details'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Solo Ride'), findsNothing);
  });

  testWidgets('renders the whole panel as a skeleton while loading', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(isLoadingFare: true));

    expect(find.byKey(const ValueKey('ride-options-loading')), findsOneWidget);
    expect(find.text('Trip Details'), findsNothing);
    expect(find.text('Set your offer'), findsNothing);
    expect(find.text('Add a tip'), findsNothing);
    expect(find.text('Add a trip note'), findsNothing);
    expect(
      find.byKey(const ValueKey('ride-options-loading-primary-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ride-options-loading-total-fare')),
      findsOneWidget,
    );
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

    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Current location'), findsOneWidget);
    expect(find.text('Central Park'), findsOneWidget);
    expect(find.text('Calculated fare'), findsNothing);
    expect(find.text('Offer'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Book directly'), findsOneWidget);
    expect(find.text('Solo Ride'), findsNothing);
    expect(find.text('4.2 km'), findsNothing);
    expect(find.text('12 min'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Hero), findsNothing);
    expect(find.byType(HeroMode), findsNothing);
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
    expect(find.text('Your offer: ₱40.00'), findsOneWidget);
  });

  testWidgets('opens a custom offer view and cancels with back', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    await tester.tap(find.byKey(const ValueKey('custom-offer-trigger')));
    await tester.pumpAndSettle();

    expect(find.text('Set your offer'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-offer-save')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('panel-back')));
    await tester.pumpAndSettle();

    expect(find.text('Set your offer'), findsNothing);
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

  testWidgets(
    'enforces 160 character limit on pickup note input and clamps preset additions',
    (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildPanel(notesController: controller));

      await tester.tap(find.byKey(const ValueKey('trip-note-trigger')));
      await tester.pumpAndSettle();

      final noteInput = find.byKey(const ValueKey('trip-note-input'));
      final longNote = 'A' * 200;
      await tester.enterText(noteInput, longNote);
      await tester.pumpAndSettle();

      expect(controller.text.length, 160);

      await tester.tap(find.text('Wait at lobby'));
      await tester.pumpAndSettle();

      expect(controller.text.length, 160);
    },
  );

  testWidgets('shows a dynamic passenger and transparent fare calculation', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel(offeredFare: '35.00', totalFare: 35));

    final fareSummary = find.byKey(const ValueKey('fare-summary'));
    await tester.ensureVisible(fareSummary);
    await tester.tap(fareSummary);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fare-details')), findsOneWidget);
    expect(find.text('Avery Cruz'), findsOneWidget);
    expect(find.text('Base fare'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Calculated fare'), findsOneWidget);
    expect(find.text('Custom offer adjustment'), findsOneWidget);
    expect(find.text('+₱6.83'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('fare-details')), findsNothing);
    expect(find.byKey(const ValueKey('trip-summary-card')), findsOneWidget);
  });

  testWidgets('selects a tip from the tip view', (tester) async {
    var selectedTip = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => buildPanel(
          selectedTipAmount: selectedTip,
          onTipSelected: (amount) => setState(() => selectedTip = amount),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('tip-trigger')));
    await tester.pumpAndSettle();

    expect(find.text('Tip your driver'), findsOneWidget);
    expect(
      find.text('100% of your tip goes directly to the driver.'),
      findsOneWidget,
    );

    await tester.tap(find.text('₱20'));
    await tester.pump();
    expect(selectedTip, 20);

    await tester.tap(find.byKey(const ValueKey('tip-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tip your driver'), findsNothing);
    expect(find.text('Tip: ₱20.00'), findsOneWidget);
  });

  testWidgets('renders anchored book directly action and trip summary', (
    tester,
  ) async {
    await tester.pumpWidget(buildPanel());

    expect(find.byKey(const ValueKey('book-directly-button')), findsOneWidget);
    expect(find.text('Book directly'), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-summary-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('total-fare-amount')), findsOneWidget);
  });

  testWidgets('shows only the primary destination name', (tester) async {
    const longAddress =
        '1390 Pear Avenue, Mountain View, California 94043, United States of America';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: RideTripSummary(
                pickupLabel: 'Mountain View',
                destinationName: 'Silicon Valley Corporate Catering',
                destinationAddress: longAddress,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Silicon Valley Corporate Catering'), findsOneWidget);
    expect(find.text(longAddress), findsNothing);
    expect(find.byKey(const ValueKey('trip-route-dashes')), findsOneWidget);
    expect(find.byIcon(LucideIcons.map_pin), findsOneWidget);
    expect(find.byIcon(LucideIcons.navigation), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints ==
                const BoxConstraints.tightFor(width: 6, height: 6),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints ==
                const BoxConstraints.tightFor(width: 18, height: 18),
      ),
      findsNothing,
    );
    expect(
      tester.widget<Icon>(find.byIcon(LucideIcons.navigation)).color,
      AppTheme.main.colorScheme.primary,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows long trip-summary labels to wrap before truncating', (
    tester,
  ) async {
    const longDestination =
        'International Convention Center and Passenger Terminal';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: RideTripSummary(
                pickupLabel: 'Pickup at the North Entrance',
                destinationName: longDestination,
                destinationAddress: 'Long address',
              ),
            ),
          ),
        ),
      ),
    );

    final destination = tester.widget<Text>(find.text(longDestination));
    expect(tester.getSize(find.byWidget(destination)).height, greaterThan(20));
    expect(tester.takeException(), isNull);
  });
}
