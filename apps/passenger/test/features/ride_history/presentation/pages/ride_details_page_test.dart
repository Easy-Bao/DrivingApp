import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_counterparty.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/ride_details_page.dart';

class _DetailsCubit extends MockCubit<RideDetailsState>
    implements RideDetailsCubit {}

class _TrackRepository extends Mock implements TrackRepository {}

class _SessionStore extends Mock implements SessionStore {}

class _ProfileRepository extends Mock implements DriverProfileRepository {}

void main() {
  testWidgets(
    'receipt shows route and fare directly without redundant completion controls',
    (tester) async {
      final cubit = _DetailsCubit();
      when(() => cubit.state).thenReturn(const RideDetailsState());
      when(() => cubit.load('receipt')).thenAnswer((_) async {});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: RideDetailsPage(
            trackRepository: _TrackRepository(),
            sessionService: _SessionStore(),
            profileRepository: _ProfileRepository(),
            detailsCubit: cubit,
            initialRide: const RideSnapshot(
              id: 'receipt',
              status: 'completed',
              pickupName: 'Receipt pickup',
              dropoffName: 'Receipt destination',
              fareAmount: 2860,
            ),
          ),
        ),
      );
      expect(find.text('Receipt pickup'), findsOneWidget);
      expect(find.text('Receipt destination'), findsOneWidget);
      expect(find.text('₱28.60'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Report an issue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final allowed in [false, true]) {
    testWidgets(
      'receipt fits large text and respects contact access $allowed',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = _DetailsCubit();
        when(() => cubit.state).thenReturn(
          RideDetailsState(
            passengerId: 'passenger',
            counterparty: RideCounterparty(
              userId: 'driver',
              name: 'Xyrel D. Tenefrancia',
              phone: '+639171234567',
              contactAllowed: allowed,
            ),
          ),
        );
        when(() => cubit.load('receipt')).thenAnswer((_) async {});
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: RideDetailsPage(
                trackRepository: _TrackRepository(),
                sessionService: _SessionStore(),
                profileRepository: _ProfileRepository(),
                detailsCubit: cubit,
                initialRide: const RideSnapshot(
                  id: 'receipt',
                  bookingReference: '701629644613868',
                  status: 'completed',
                  pickupName: 'Mountain View',
                  dropoffName: 'Google Cafe',
                  fareAmount: 2759,
                  distanceKm: 0.578,
                  durationMinutes: 7,
                ),
              ),
            ),
          ),
        );
        expect(find.text('701629644613868'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('578 m · 7 min'), findsOneWidget);
        expect(
          find.byTooltip('Call driver'),
          allowed ? findsOneWidget : findsNothing,
        );
        expect(
          find.byTooltip('Message driver'),
          allowed ? findsOneWidget : findsNothing,
        );
        expect(find.text('+639171234567'), findsNothing);
        await tester.ensureVisible(find.text('Report an issue'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'keeps existing rating instead of showing Rate this ride when review resolves before ride details',
    (tester) async {
      final trackRepository = _TrackRepository();
      final sessionStore = _SessionStore();
      final profileRepository = _ProfileRepository();
      final rideCompleter = Completer<Result<RideSnapshot, Failure>>();
      final counterpartyCompleter =
          Completer<Result<RideCounterparty, Failure>>();

      when(() => sessionStore.readPassengerId())
          .thenAnswer((_) async => 'passenger-1');
      when(() => trackRepository.fetchRide('901'))
          .thenAnswer((_) => rideCompleter.future);
      when(() => trackRepository.fetchCounterparty('901'))
          .thenAnswer((_) => counterpartyCompleter.future);
      when(() => profileRepository.fetchMyRideReview('901')).thenAnswer(
        (_) async => const Ok(
          DriverReview(
            passengerName: 'Passenger',
            comment: 'Great ride',
            rating: 5,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: RideDetailsPage(
            trackRepository: trackRepository,
            sessionService: sessionStore,
            profileRepository: profileRepository,
            initialRide: const RideSnapshot(
              id: '901',
              status: 'completed',
              pickupName: 'Mountain View',
              dropoffName: 'Cafe',
              driverId: 'driver-1',
              driverName: 'Xyrel D. Tenefrancia',
              fareAmount: 2631,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rate this ride'), findsNothing);

      rideCompleter.complete(
        const Ok(
          RideSnapshot(
            id: '901',
            status: 'completed',
            pickupName: 'Mountain View',
            dropoffName: 'Cafe',
            driverId: 'driver-1',
            driverName: 'Xyrel D. Tenefrancia',
            fareAmount: 2631,
          ),
        ),
      );
      counterpartyCompleter.complete(
        const Err(ServerFailure('Contact unavailable')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ride rating'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Rate this ride'), findsNothing);
    },
  );

  testWidgets(
    'shows Rate this ride only after unrated review status finishes loading',
    (tester) async {
      final trackRepository = _TrackRepository();
      final sessionStore = _SessionStore();
      final profileRepository = _ProfileRepository();
      final reviewCompleter = Completer<Result<DriverReview?, Failure>>();

      when(() => sessionStore.readPassengerId())
          .thenAnswer((_) async => 'passenger-1');
      when(() => trackRepository.fetchRide('902')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: '902',
            status: 'completed',
            pickupName: 'Mountain View',
            dropoffName: 'Cafe',
            driverId: 'driver-1',
            driverName: 'Xyrel D. Tenefrancia',
            fareAmount: 2631,
          ),
        ),
      );
      when(() => trackRepository.fetchCounterparty('902')).thenAnswer(
        (_) async => const Err(ServerFailure('Contact unavailable')),
      );
      when(() => profileRepository.fetchMyRideReview('902'))
          .thenAnswer((_) => reviewCompleter.future);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: RideDetailsPage(
            trackRepository: trackRepository,
            sessionService: sessionStore,
            profileRepository: profileRepository,
            initialRide: const RideSnapshot(
              id: '902',
              status: 'completed',
              pickupName: 'Mountain View',
              dropoffName: 'Cafe',
              driverId: 'driver-1',
              driverName: 'Xyrel D. Tenefrancia',
              fareAmount: 2631,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Rate this ride'), findsNothing);

      reviewCompleter.complete(const Ok(null));
      await tester.pumpAndSettle();
      expect(find.text('Rate this ride'), findsOneWidget);
    },
  );

  testWidgets(
    'fetches review once on failure without looping and preserves caller cubit lifecycle',
    (tester) async {
      final trackRepository = _TrackRepository();
      final sessionStore = _SessionStore();
      final profileRepository = _ProfileRepository();

      when(() => sessionStore.readPassengerId())
          .thenAnswer((_) async => 'passenger-1');
      when(() => trackRepository.fetchRide('903')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: '903',
            status: 'completed',
            pickupName: 'Mountain View',
            dropoffName: 'Cafe',
            driverId: 'driver-1',
            driverName: 'Xyrel D. Tenefrancia',
            fareAmount: 2631,
          ),
        ),
      );
      when(() => trackRepository.fetchCounterparty('903')).thenAnswer(
        (_) async => const Err(ServerFailure('Contact unavailable')),
      );
      when(() => profileRepository.fetchMyRideReview('903')).thenAnswer(
        (_) async => const Err(NetworkFailure('Review fetch failed')),
      );

      final injectedCubit = RideDetailsCubit(
        repository: trackRepository,
        sessionService: sessionStore,
        profileRepository: profileRepository,
      );
      addTearDown(injectedCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: RideDetailsPage(
            trackRepository: trackRepository,
            sessionService: sessionStore,
            profileRepository: profileRepository,
            detailsCubit: injectedCubit,
            initialRide: const RideSnapshot(
              id: '903',
              status: 'completed',
              pickupName: 'Mountain View',
              dropoffName: 'Cafe',
              driverId: 'driver-1',
              driverName: 'Xyrel D. Tenefrancia',
              fareAmount: 2631,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => profileRepository.fetchMyRideReview('903')).called(1);
      expect(find.text('Rate this ride'), findsNothing);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
      expect(injectedCubit.isClosed, isFalse);
    },
  );
}
