import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

class MockSessionStore extends Mock implements SessionStore {}

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

void main() {
  late MockTrackRepository repository;
  late MockSessionStore sessionService;
  late MockDriverProfileRepository profileRepository;

  setUp(() {
    repository = MockTrackRepository();
    sessionService = MockSessionStore();
    profileRepository = MockDriverProfileRepository();
    when(() => sessionService.readPassengerId())
        .thenAnswer((_) async => 'passenger-1');
  });

  test('coalesces repeated detail loads for the same ride', () async {
    final rideCompleter = Completer<Result<RideSnapshot, Failure>>();
    final counterpartyCompleter =
        Completer<Result<RideCounterparty, Failure>>();
    const ride = RideSnapshot(
      id: '303',
      status: 'completed',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
    );
    const counterparty = RideCounterparty(
      userId: 'driver-1',
      name: 'Driver',
      phone: '+639171234567',
      contactAllowed: true,
    );
    when(() => repository.fetchRide('303'))
        .thenAnswer((_) => rideCompleter.future);
    when(() => repository.fetchCounterparty('303'))
        .thenAnswer((_) => counterpartyCompleter.future);

    final cubit = RideDetailsCubit(
      repository: repository,
      sessionService: sessionService,
      profileRepository: profileRepository,
    );
    final firstLoad = cubit.load('303');
    final secondLoad = cubit.load('303');

    verify(() => repository.fetchRide('303')).called(1);
    verify(() => repository.fetchCounterparty('303')).called(1);

    rideCompleter.complete(const Ok(ride));
    counterpartyCompleter.complete(const Ok(counterparty));
    await Future.wait([firstLoad, secondLoad]);

    expect(cubit.state.ride, ride);
    expect(cubit.state.counterparty, counterparty);
    expect(cubit.state.passengerId, 'passenger-1');
    expect(cubit.state.canContactCounterparty, isTrue);
    await cubit.close();
  });

  test(
    'canContactCounterparty is false when driver contact is not allowed',
    () async {
      const counterparty = RideCounterparty(
        userId: 'driver-2',
        name: 'Driver Two',
        phone: '+639170000000',
        contactAllowed: false,
      );
      when(() => repository.fetchRide('404')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: '404',
            status: 'completed',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
          ),
        ),
      );
      when(() => repository.fetchCounterparty('404'))
          .thenAnswer((_) async => const Ok(counterparty));

      final cubit = RideDetailsCubit(
        repository: repository,
        sessionService: sessionService,
        profileRepository: profileRepository,
      );
      await cubit.load('404');

      expect(cubit.state.counterparty, counterparty);
      expect(cubit.state.canContactCounterparty, isFalse);
      await cubit.close();
    },
  );

  test(
    'canContactCounterparty is false when counterparty has empty user ID',
    () async {
      const counterparty = RideCounterparty(
        userId: '',
        name: 'Driver Three',
        phone: '+639170000000',
        contactAllowed: true,
      );
      when(() => repository.fetchRide('505')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: '505',
            status: 'completed',
            pickupName: 'Pickup',
            dropoffName: 'Dropoff',
          ),
        ),
      );
      when(() => repository.fetchCounterparty('505'))
          .thenAnswer((_) async => const Ok(counterparty));

      final cubit = RideDetailsCubit(
        repository: repository,
        sessionService: sessionService,
        profileRepository: profileRepository,
      );
      await cubit.load('505');

      expect(cubit.state.counterparty, counterparty);
      expect(cubit.state.canContactCounterparty, isFalse);
      await cubit.close();
    },
  );

  test('loads and submits a ride rating through presentation state', () async {
    when(() => repository.fetchRide('606')).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: '606',
          status: 'completed',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
        ),
      ),
    );
    when(() => repository.fetchCounterparty('606')).thenAnswer(
      (_) async => const Err(ServerFailure('Contact details unavailable.')),
    );
    when(() => profileRepository.fetchMyRideReview('606'))
        .thenAnswer((_) async => const Ok(null));
    when(
      () => profileRepository.submitReview(
        driverId: 'driver-6',
        rideId: '606',
        rating: 5,
        comment: 'Great trip',
      ),
    ).thenAnswer((_) async => const Ok(null));

    final cubit = RideDetailsCubit(
      repository: repository,
      sessionService: sessionService,
      profileRepository: profileRepository,
    );
    await cubit.load('606');
    await cubit.loadMyReview('606');
    expect(cubit.state.isLoadingReview, isFalse);
    expect(cubit.state.submittedReview, isNull);

    await cubit.submitRating(
      driverId: 'driver-6',
      rideId: '606',
      rating: 5,
      comment: 'Great trip',
    );

    expect(cubit.state.isSubmittingReview, isFalse);
    expect(cubit.state.submittedReview?.rating, 5);
    expect(cubit.state.submittedReview?.comment, 'Great trip');
    verify(
      () => profileRepository.submitReview(
        driverId: 'driver-6',
        rideId: '606',
        rating: 5,
        comment: 'Great trip',
      ),
    ).called(1);
    await cubit.close();
  });

  test(
    'surfaces the specific failure message when loading ride details fails',
    () async {
      when(
        () => repository.fetchRideResult('707'),
      ).thenAnswer((_) async => const Err(NetworkFailure.serverUnreachable()));
      when(
        () => repository.fetchCounterpartyResult('707'),
      ).thenAnswer((_) async => const Err(NetworkFailure.serverUnreachable()));

      final cubit = RideDetailsCubit(
        repository: repository,
        sessionService: sessionService,
        profileRepository: profileRepository,
      );
      await cubit.load('707');

      expect(
        cubit.state.errorMessage,
        'Cannot reach the server. Check that the server is running and try again.',
      );
      await cubit.close();
    },
  );

  test(
    'preserves an existing ride review when loadMyReview completes before load',
    () async {
      final rideCompleter = Completer<Result<RideSnapshot, Failure>>();
      final counterpartyCompleter =
          Completer<Result<RideCounterparty, Failure>>();
      const ride = RideSnapshot(
        id: '808',
        status: 'completed',
        pickupName: 'Pickup',
        dropoffName: 'Dropoff',
        driverId: 'driver-8',
      );
      const existingReview = DriverReview(
        passengerName: 'Passenger',
        comment: 'Smooth trip',
        rating: 5,
      );

      when(() => repository.fetchRide('808'))
          .thenAnswer((_) => rideCompleter.future);
      when(() => repository.fetchCounterparty('808'))
          .thenAnswer((_) => counterpartyCompleter.future);
      when(() => profileRepository.fetchMyRideReview('808'))
          .thenAnswer((_) async => const Ok(existingReview));

      final cubit = RideDetailsCubit(
        repository: repository,
        sessionService: sessionService,
        profileRepository: profileRepository,
      );

      final loadFuture = cubit.load('808');
      await cubit.loadMyReview('808');

      expect(cubit.state.hasLoadedReview, isTrue);
      expect(cubit.state.submittedReview, existingReview);

      rideCompleter.complete(const Ok(ride));
      counterpartyCompleter.complete(
        const Err(ServerFailure('Contact unavailable')),
      );
      await loadFuture;

      expect(cubit.state.ride, ride);
      expect(cubit.state.hasLoadedReview, isTrue);
      expect(cubit.state.submittedReview, existingReview);
      await cubit.close();
    },
  );

  test('does not loop failed review fetches until an explicit refresh is requested', () async {
    when(() => repository.fetchRide('909')).thenAnswer(
      (_) async => const Ok(
        RideSnapshot(
          id: '909',
          status: 'completed',
          pickupName: 'Pickup',
          dropoffName: 'Dropoff',
          driverId: 'driver-9',
        ),
      ),
    );
    when(
      () => repository.fetchCounterparty('909'),
    ).thenAnswer((_) async => const Err(ServerFailure('Contact unavailable')));
    when(() => profileRepository.fetchMyRideReview('909')).thenAnswer(
      (_) async => const Err(NetworkFailure('Review temporarily unavailable')),
    );

    final cubit = RideDetailsCubit(
      repository: repository,
      sessionService: sessionService,
      profileRepository: profileRepository,
    );
    await cubit.load('909');
    await cubit.loadMyReview('909');
    await cubit.loadMyReview('909');

    verify(() => profileRepository.fetchMyRideReview('909')).called(1);
    expect(cubit.state.reviewErrorMessage, isNotNull);

    when(() => profileRepository.fetchMyRideReview('909'))
        .thenAnswer((_) async => const Ok(null));
    await cubit.loadMyReview('909', refresh: true);

    verify(() => profileRepository.fetchMyRideReview('909')).called(1);
    expect(cubit.state.hasLoadedReview, isTrue);
    expect(cubit.state.reviewErrorMessage, isNull);
    await cubit.close();
  });

  test(
    'retries ride details after partial failure and on forced reload',
    () async {
      const ride = RideSnapshot(
        id: '910',
        status: 'completed',
        pickupName: 'Pickup',
        dropoffName: 'Dropoff',
      );
      const counterparty = RideCounterparty(
        userId: 'driver-10',
        name: 'Driver Ten',
        phone: '+639171234567',
        contactAllowed: true,
      );
      when(() => repository.fetchRide('910'))
          .thenAnswer((_) async => const Ok(ride));
      var counterpartyCalls = 0;
      when(() => repository.fetchCounterparty('910')).thenAnswer((_) async {
        counterpartyCalls += 1;
        if (counterpartyCalls == 1) {
          return const Err(NetworkFailure('Temporary failure'));
        }
        return const Ok(counterparty);
      });

      final cubit = RideDetailsCubit(
        repository: repository,
        sessionService: sessionService,
        profileRepository: profileRepository,
      );
      await cubit.load('910');
      expect(cubit.state.ride, ride);
      expect(cubit.state.counterparty, isNull);

      await cubit.load('910');
      expect(cubit.state.counterparty, counterparty);

      await cubit.load('910');
      verify(() => repository.fetchRide('910')).called(2);

      await cubit.load('910', force: true);
      verify(() => repository.fetchRide('910')).called(1);
      await cubit.close();
    },
  );
}
