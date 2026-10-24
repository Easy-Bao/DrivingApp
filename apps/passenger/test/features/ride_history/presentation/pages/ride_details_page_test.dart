import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
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
  testWidgets('receipt details finish opening and closing in one frame', (
    tester,
  ) async {
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
    expect(find.text('Receipt pickup'), findsNothing);
    await tester.tap(find.text('Trip details'));
    await tester.pump();
    expect(find.text('Receipt pickup'), findsOneWidget);
    expect(find.text('Receipt destination'), findsOneWidget);
    await tester.tap(find.text('Trip details'));
    await tester.pump();
    expect(find.text('Receipt pickup'), findsNothing);
    expect(find.text('Receipt destination'), findsNothing);
    expect(find.text('₱28.60'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
