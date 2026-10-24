import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/presentation/view/incoming_ride_request_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _DashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

void main() {
  late _DashboardCubit cubit;
  late StreamController<DashboardState> states;
  const bid = <String, dynamic>{
    'id': 'request',
    'target_driver_id': 42,
    'offered_fare': 12000,
    'pickup_name': 'Pickup street',
    'dropoff_name': 'Destination street',
    'passenger_note': 'Outside the entrance',
  };
  const waiting = DashboardState(isOnline: true, activeBids: [bid]);

  setUp(() {
    cubit = _DashboardCubit();
    states = StreamController<DashboardState>();
    whenListen(cubit, states.stream, initialState: waiting);
    when(() => cubit.removeExpiredRideOffers()).thenReturn(false);
  });
  tearDown(() async {
    await states.close();
    await cubit.close();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => IncomingRideRequestPage(
                    cubit: cubit,
                    sessionId: 'request',
                  ),
                ),
              ),
              child: const Text('Open request'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open request'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows trip details and accepts the displayed fare once', (
    tester,
  ) async {
    final response = Completer<bool>();
    when(() => cubit.submitRideOffer(sessionId: 'request', farePesos: 120))
        .thenAnswer((_) => response.future);
    await open(tester);
    expect(find.text('A passenger chose you'), findsOneWidget);
    expect(find.text('Pickup street'), findsOneWidget);
    expect(find.text('Destination street'), findsOneWidget);
    await tester.tap(find.text('Accept ride'));
    await tester.pump();
    expect(find.text('Sending response…'), findsOneWidget);
    verify(() => cubit.submitRideOffer(sessionId: 'request', farePesos: 120))
        .called(1);
    response.complete(true);
    await tester.pump();
    expect(find.text('Confirming your trip…'), findsOneWidget);
    expect(find.text('Accept ride'), findsNothing);
    states.add(const DashboardState(isOnline: true));
    await tester.pumpAndSettle();
    expect(find.text('Open request'), findsOneWidget);
  });

  testWidgets('keeps a failed decline visible and supports retry', (
    tester,
  ) async {
    when(() => cubit.declineRideRequest('request'))
        .thenAnswer((_) async => false);
    await open(tester);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to respond. Please try again.'), findsOneWidget);
    expect(find.text('Accept ride'), findsOneWidget);
  });

  testWidgets(
    'closes when a cancelled or expired request leaves dispatch state',
    (tester) async {
      await open(tester);
      states.add(const DashboardState(isOnline: true));
      await tester.pumpAndSettle();
      expect(find.text('Open request'), findsOneWidget);
      expect(find.text('Accept ride'), findsNothing);
    },
  );
}
