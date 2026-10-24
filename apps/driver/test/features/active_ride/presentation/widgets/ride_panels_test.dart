import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/pickup_navigation_panel.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/waiting_passenger_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'pickup actions fit compact viewport dark=$dark scale=$scale',
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
                    child: PickupNavigationPanel(
                      pickup: 'Mountain View near the main entrance',
                      dropoff: 'Charleston Park',
                      passengerName: 'Passenger with a long name',
                      distance: 1,
                      fare: 27.88,
                      sliderValue: 0,
                      unreadChatMessagesCount: 3,
                      onSliderChanged: (_) {},
                      onSliderCompleted: () {},
                      onCancelPressed: () {},
                      onChatPressed: () => chats++,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.byTooltip('Call passenger'), findsNothing);
          await tester.ensureVisible(find.byTooltip('Chat with passenger'));
          await tester.tap(find.byTooltip('Chat with passenger'));
          expect(chats, 1);
          await tester.ensureVisible(find.text('Cancel ride'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('waiting panel leaves one primary start action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: WaitingPassengerPanel(
            pickup: 'Mountain View',
            dropoff: 'Charleston Park',
            passengerName: 'Passenger',
            waitFormatted: '00:02',
            fare: 27.88,
            unreadChatMessagesCount: 0,
            onStartTripPressed: () {},
            onChatPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Start Trip'), findsOneWidget);
    expect(find.byTooltip('Call passenger'), findsNothing);
    expect(find.byTooltip('Chat with passenger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
