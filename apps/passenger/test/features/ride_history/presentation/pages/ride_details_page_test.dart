import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_counterparty.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
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
}
