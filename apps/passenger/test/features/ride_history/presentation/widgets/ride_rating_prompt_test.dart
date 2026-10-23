import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_rating_prompt.dart';

class _TrackRepositoryMock extends Mock implements TrackRepository {}

class _SessionStoreMock extends Mock implements SessionStore {}

class _DriverProfileRepositoryStub implements DriverProfileRepository {
  int submittedReviews = 0;

  @override
  Future<Result<DriverProfileStats, Failure>> fetchStats(
    String driverId,
  ) async => const Ok(DriverProfileStats(completedTrips: 0));

  @override
  Future<Result<OffsetPage<DriverReview>, Failure>> fetchReviews(
    String driverId, {
    int page = 1,
    String? cursor = '',
    int limit = 20,
  }) async => const Ok(
    OffsetPage<DriverReview>(items: [], hasMore: false, nextOffset: null),
  );

  @override
  Future<Result<DriverReview?, Failure>> fetchMyRideReview(
    String rideId,
  ) async => const Ok(null);

  @override
  Future<Result<void, Failure>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    submittedReviews++;
    return const Ok(null);
  }
}

Future<RideDetailsCubit> _loadedDetailsCubit(
  DriverProfileRepository profileRepository,
) async {
  final repository = _TrackRepositoryMock();
  final sessionStore = _SessionStoreMock();
  when(() => sessionStore.readPassengerId())
      .thenAnswer((_) async => 'passenger-1');
  when(() => repository.fetchRide('ride-1')).thenAnswer(
    (_) async => const Ok(
      RideSnapshot(
        id: 'ride-1',
        status: 'completed',
        pickupName: 'Pickup',
        dropoffName: 'Dropoff',
        driverId: 'driver-1',
      ),
    ),
  );
  when(() => repository.fetchCounterparty('ride-1')).thenAnswer(
    (_) async => const Err(ServerFailure('Contact details unavailable.')),
  );

  final cubit = RideDetailsCubit(
    repository: repository,
    sessionService: sessionStore,
    profileRepository: profileRepository,
  );
  await cubit.load('ride-1');
  await cubit.loadMyReview('ride-1');
  return cubit;
}

void main() {
  testWidgets('history keeps optional rating collapsed until requested', (
    tester,
  ) async {
    final repository = _DriverProfileRepositoryStub();
    final cubit = await _loadedDetailsCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: RideRatingPrompt(
            driverId: 'driver-1',
            driverName: 'Demo Driver',
            rideId: 'ride-1',
            cubit: cubit,
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rate this ride'), findsOneWidget);
    expect(find.byTooltip('1 star'), findsNothing);
    await tester.tap(find.text('Rate this ride'));
    await tester.pump();
    expect(find.text('How was your ride with Demo Driver?'), findsOneWidget);
    expect(find.byTooltip('1 star'), findsOneWidget);
  });

  testWidgets('completion submits one rating and shows its saved value', (
    tester,
  ) async {
    final repository = _DriverProfileRepositoryStub();
    final cubit = await _loadedDetailsCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: RideRatingPrompt(
            driverId: 'driver-1',
            driverName: 'Demo Driver',
            rideId: 'ride-1',
            cubit: cubit,
            initiallyExpanded: true,
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('5 stars'));
    await tester.pump();
    await tester.tap(find.text('Submit rating'));
    await tester.pumpAndSettle();

    expect(repository.submittedReviews, 1);
    expect(find.text('You rated this ride 5 stars'), findsOneWidget);
    expect(find.byTooltip('5 stars'), findsOneWidget);
  });
}
