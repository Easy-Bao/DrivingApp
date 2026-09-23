import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

class MockPassengerSessionStore extends Mock implements PassengerSessionStore {}

void main() {
  late MockTrackRepository repository;
  late MockPassengerSessionStore sessionService;

  setUp(() {
    repository = MockTrackRepository();
    sessionService = MockPassengerSessionStore();
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
}
