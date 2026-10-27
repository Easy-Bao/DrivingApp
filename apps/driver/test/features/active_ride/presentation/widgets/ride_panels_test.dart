import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_trip_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final state in <RideState>[
    const RideFlowNavigatingToPickup(
      passengerName: 'Passenger with a long name',
    ),
    const RideFlowWaitingPassenger(
      passengerName: 'Passenger with a long name',
      waitTimeSeconds: 35,
    ),
    const RideFlowInTransit(passengerName: 'Passenger with a long name'),
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'trip stage ${state.runtimeType} fits compact viewport dark=$dark scale=$scale',
          (tester) async {
            tester.view.physicalSize = const Size(320, 480);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var chats = 0;
            await tester.pumpWidget(
              MaterialApp(
                theme: dark
                    ? AppTheme.main.copyWith(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: AppTheme.main.colorScheme.primary,
                          brightness: Brightness.dark,
                        ),
                      )
                    : AppTheme.main,
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: DriverTripPanel(
                        state: state,
                        pickup: 'Mountain View near the main entrance',
                        dropoff: 'Charleston Park',
                        fare: 27.88,
                        progress: 0,
                        isBusy: false,
                        unreadCount: 3,
                        onProgressChanged: (_) {},
                        onAdvance: () {},
                        onChat: () => chats++,
                        onCancel: () {},
                        onNoShow: null,
                        noShowRemaining: const Duration(minutes: 2),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(SnackBar), findsNothing);
            expect(find.byTooltip('Call passenger'), findsNothing);
            expect(find.textContaining('Booking ID'), findsNothing);
            await tester.ensureVisible(find.byTooltip('Chat with passenger'));
            await tester.tap(find.byTooltip('Chat with passenger'));
            expect(chats, 1);
            if (state.isWaitingAtPickup) {
              await tester.ensureVisible(find.text('Start trip'));
              expect(find.text('No-show available in 02:00'), findsOneWidget);
            } else if (state is TripInProgress) {
              expect(find.text('Cancel ride'), findsNothing);
              expect(find.text('Charleston Park'), findsOneWidget);
            } else {
              expect(
                find.text('Mountain View near the main entrance'),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
