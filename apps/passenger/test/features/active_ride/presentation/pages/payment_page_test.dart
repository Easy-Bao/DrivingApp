import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/payment_page.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class _MockTrackRepository extends Mock implements TrackRepository {}

class _MockSessionStore extends Mock implements SessionStore {}

class _MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

void main() {
  const testRide = RideSnapshot(
    id: 'ride-123',
    pickupName: 'Ayala Center',
    dropoffName: 'IT Park',
    status: 'completed',
    driverId: 'driver-456',
    driverName: 'Juan Dela Cruz',
    plateNumber: 'ABC 1234',
    vehicleType: 'Sedan',
    fareAmount: 18500,
  );

  late _MockTrackRepository trackRepository;
  late _MockSessionStore sessionService;
  late _MockDriverProfileRepository profileRepository;

  setUp(() {
    trackRepository = _MockTrackRepository();
    sessionService = _MockSessionStore();
    profileRepository = _MockDriverProfileRepository();
    when(() => sessionService.readPassengerId())
        .thenAnswer((_) async => 'passenger-789');
    when(() => trackRepository.fetchRide(any()))
        .thenAnswer((_) async => const Ok(testRide));
    when(() => trackRepository.fetchCounterparty(any())).thenAnswer(
      (_) async => const Err(ServerFailure('Contact details unavailable.')),
    );
    when(() => profileRepository.fetchMyRideReview(any()))
        .thenAnswer((_) async => const Ok<DriverReview?, Failure>(null));
  });

  testWidgets('completion opens the shared receipt and rating composition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: PaymentPage(
          ride: testRide,
          trackRepository: trackRepository,
          sessionService: sessionService,
          profileRepository: profileRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip receipt'), findsOneWidget);
    expect(find.text('Booking ID - ride-123'), findsOneWidget);
    expect(find.text('Total fare'), findsOneWidget);
    expect(find.text('₱185.00'), findsOneWidget);
    expect(find.text('Cash · Awaiting driver confirmation.'), findsOneWidget);
    expect(find.text('How was your ride with Juan Dela Cruz?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared receipt remains scrollable on a compact screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: PaymentPage(
          ride: testRide,
          trackRepository: trackRepository,
          sessionService: sessionService,
          profileRepository: profileRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip receipt'), findsOneWidget);
    expect(find.text('Booking ID - ride-123'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
