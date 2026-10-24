import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/trip_completion_page.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

class _TrackRepository extends Mock implements TrackRepository {}

class _SessionStore extends Mock implements SessionStore {}

class _ProfileRepository extends Mock implements DriverProfileRepository {}

const _ride = RideSnapshot(
  id: 'ride-1',
  status: 'completed',
  pickupName: 'Pickup',
  dropoffName: 'Destination',
  driverId: 'driver-1',
  driverName: 'Alex Driver',
  fareAmount: 18500,
);

void main() {
  late _ProfileRepository profile;
  late RideDetailsCubit cubit;
  late GoRouter router;

  setUp(() {
    final track = _TrackRepository();
    final session = _SessionStore();
    profile = _ProfileRepository();
    when(() => track.fetchRide('ride-1'))
        .thenAnswer((_) async => const Ok(_ride));
    when(() => track.fetchCounterparty('ride-1'))
        .thenAnswer((_) async => const Err(NetworkFailure('Unavailable')));
    when(() => session.readPassengerId())
        .thenAnswer((_) async => 'passenger-1');
    when(() => profile.fetchMyRideReview('ride-1'))
        .thenAnswer((_) async => const Ok<DriverReview?, Failure>(null));
    when(
      () => profile.submitReview(
        driverId: 'driver-1',
        rideId: 'ride-1',
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    cubit = RideDetailsCubit(
      repository: track,
      sessionService: session,
      profileRepository: profile,
    );
    router = GoRouter(
      initialLocation: '/completed',
      routes: [
        GoRoute(
          path: '/',
          name: HomeRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/completed',
          builder: (_, _) =>
              TripCompletionPage(ride: _ride, detailsCubit: cubit),
        ),
        GoRoute(
          path: '/receipt',
          name: RideHistoryRoutes.rideDetails,
          builder: (context, state) {
            expect(state.extra, (ride: _ride, showRatingAction: false));
            return Scaffold(
              appBar: AppBar(title: const Text('Receipt')),
              body: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to completion'),
              ),
            );
          },
        ),
      ],
    );
  });
  tearDown(() => router.dispose());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.main, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('completion has one finish action and no mandatory rating', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Ride completed'), findsOneWidget);
    expect(find.text('₱185.00'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Comment (optional)'), findsNothing);
    expect(find.text('Trip details'), findsNothing);
    expect(find.text('Submit rating'), findsNothing);
    expect(find.text('Not now'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    verifyNever(
      () => profile.submitReview(
        driverId: any(named: 'driverId'),
        rideId: any(named: 'rideId'),
        rating: any(named: 'rating'),
        comment: any(named: 'comment'),
      ),
    );
  });

  testWidgets('selected stars reveal feedback and Done saves exactly once', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('2 stars'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextField),
      'Please drive more carefully',
    );
    await tester.tap(find.text('Done'));
    await tester.tap(find.text('Done'), warnIfMissed: false);
    await tester.pumpAndSettle();
    verify(
      () => profile.submitReview(
        driverId: 'driver-1',
        rideId: 'ride-1',
        rating: 2,
        comment: 'Please drive more carefully',
      ),
    ).called(1);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('failed rating keeps the draft and offers retry through Done', (
    tester,
  ) async {
    when(
      () => profile.submitReview(
        driverId: 'driver-1',
        rideId: 'ride-1',
        rating: 2,
        comment: 'Too fast',
      ),
    ).thenAnswer(
      (_) async => const Err(NetworkFailure('Unable to save feedback.')),
    );
    await open(tester);
    await tester.tap(find.byTooltip('2 stars'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Too fast');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.text('Too fast'), findsOneWidget);
    expect(cubit.state.ratingErrorMessage, isNotNull);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('optional receipt preserves the rating draft on return', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Comfortable ride');
    await tester.ensureVisible(find.text('View receipt'));
    await tester.tap(find.text('View receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt'), findsOneWidget);
    await tester.tap(find.text('Back to completion'));
    await tester.pumpAndSettle();
    expect(find.text('Comfortable ride'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('completion scrolls with large text on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.main,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('5 stars'));
    await tester.tap(find.byTooltip('5 stars'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Done'), findsOneWidget);
  });
}
