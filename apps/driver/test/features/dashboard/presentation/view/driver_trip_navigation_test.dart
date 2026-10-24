import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/presentation/view/driver_dashboard_page.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:go_router/go_router.dart' show GoRouter;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:mocktail/mocktail.dart';

class _Dashboard extends MockCubit<DashboardState> implements DashboardCubit {}

class _RideFlow extends MockCubit<RideFlowState> implements RideFlowCubit {}

class _Location extends MockCubit<LocationAccessViewState>
    implements LocationAccessCubit {}

void main() {
  for (final status in ['accepted', 'arrived', 'in_transit']) {
    for (final scenario in ['assignment', 'restored', 'retry']) {
      testWidgets(
        'opens the $status trip stage after $scenario without a dashboard card',
        (tester) async {
          final dashboard = _Dashboard();
          final flow = _RideFlow();
          final location = _Location();
          final states = StreamController<DashboardState>();
          final lifecycle = AppLifecycleCoordinator();
          final realtime = RealtimeWebSocketClient(
            uri: Uri.parse('ws://example.test'),
            tokenProvider: () async => null,
          );
          final trip = RideSnapshot(
            id: 'trip',
            status: status,
            pickupName: 'Pickup',
            dropoffName: 'Destination',
            distanceKm: 2,
            durationMinutes: 5,
            fareAmount: 2800,
          );
          whenListen(
            dashboard,
            states.stream,
            initialState: scenario == 'restored'
                ? DashboardState(activeRide: trip)
                : const DashboardState(),
          );
          when(() => flow.state).thenReturn(const Idle());
          when(() => location.state).thenReturn(const LocationAccessReady());
          when(() => flow.restorePendingCashSettlement())
              .thenAnswer((_) async => null);
          when(
            () => dashboard.loadDispatchSnapshot(
              includeOffers: false,
              silent: true,
            ),
          ).thenAnswer((_) async => true);
          when(() => dashboard.removeExpiredRideOffers()).thenReturn(false);
          var fetchCount = 0;
          when(() => dashboard.fetchAuthoritativeRide('trip'))
              .thenAnswer((_) async {
                fetchCount++;
                return scenario == 'retry' && fetchCount == 1 ? null : trip;
              });
          when(
            () => flow.resumeRide(
              rideId: any(named: 'rideId'),
              bookingReference: any(named: 'bookingReference'),
              status: any(named: 'status'),
              passengerName: any(named: 'passengerName'),
              passengerId: any(named: 'passengerId'),
              distanceKm: any(named: 'distanceKm'),
              pickupLatitude: any(named: 'pickupLatitude'),
              pickupLongitude: any(named: 'pickupLongitude'),
              destinationLatitude: any(named: 'destinationLatitude'),
              destinationLongitude: any(named: 'destinationLongitude'),
              arrivedAt: any(named: 'arrivedAt'),
              waitingUntil: any(named: 'waitingUntil'),
            ),
          ).thenAnswer((_) async => true);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => DashboardPage(
                  lifecycleCoordinator: lifecycle,
                  realtimeClient: realtime,
                ),
              ),
              GoRoute(
                path: '/pickup',
                name: ActiveRideRoutes.pickupNavigation,
                builder: (_, _) => const Scaffold(body: Text('Pickup stage')),
              ),
              GoRoute(
                path: '/waiting',
                name: ActiveRideRoutes.waitingPassenger,
                builder: (_, _) => const Scaffold(body: Text('Waiting stage')),
              ),
              GoRoute(
                path: '/transit',
                name: ActiveRideRoutes.inTransit,
                builder: (_, _) => const Scaffold(body: Text('Transit stage')),
              ),
            ],
          );
          await tester.pumpWidget(
            MultiBlocProvider(
              providers: [
                BlocProvider<DashboardCubit>.value(value: dashboard),
                BlocProvider<RideFlowCubit>.value(value: flow),
                BlocProvider<LocationAccessCubit>.value(value: location),
              ],
              child: MaterialApp.router(
                theme: AppTheme.main,
                routerConfig: router,
              ),
            ),
          );
          await tester.pump();
          if (scenario != 'restored') {
            states.add(DashboardState(activeRide: trip));
          }
          await tester.pumpAndSettle();
          if (scenario == 'retry') {
            expect(
              find.text(
                'Your trip could not be opened. Refresh its status and try again.',
              ),
              findsOneWidget,
            );
            await tester.tap(find.text('Try again'));
            await tester.pumpAndSettle();
          }
          expect(
            find.text(switch (status) {
              'arrived' => 'Waiting stage',
              'in_transit' => 'Transit stage',
              _ => 'Pickup stage',
            }),
            findsOneWidget,
          );
          verify(() => dashboard.fetchAuthoritativeRide('trip'))
              .called(scenario == 'retry' ? 2 : 1);
          expect(find.text('Continue Navigation'), findsNothing);
          expect(find.textContaining('Booking ID'), findsNothing);
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await states.close();
          await lifecycle.dispose();
          await realtime.dispose();
          await dashboard.close();
          await flow.close();
          await location.close();
        },
      );
    }
  }
}
