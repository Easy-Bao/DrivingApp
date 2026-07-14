import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTrackRepo extends Mock implements TrackRepository {}

TrackDriverCubit _makeCubit(TrackRepository repo) =>
    TrackDriverCubit(repository: repo);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTrackRepo repo;

  setUp(() {
    repo = MockTrackRepo();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(RideStatus.unknown);
  });

  group('TrackDriverCubit — initial state', () {
    test('starts with TrackDriverInitial', () async {
      final cubit = _makeCubit(repo);
      expect(cubit.state, isA<TrackDriverInitial>());
      await cubit.close();
    });
  });

  group('TrackDriverCubit — cancelTrip()', () {
    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverCanceled',
      build: () {
        when(
          () => repo.updateRideStatus(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        return _makeCubit(repo);
      },
      act: (cubit) => cubit.cancelTrip(),
      expect: () => [isA<TrackDriverCanceled>()],
    );
  });

  group('TrackDriverCubit — startTracking()', () {
    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits at least one TrackDriverInProgress when repo returns route',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer(
          (_) async => [
            [123.434, 7.828],
            [123.435, 7.829],
            [123.436, 7.830],
          ],
        );
        when(
          () => repo.getRideStatusUpdate(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('error')));
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );

    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits at least one TrackDriverInProgress when repo returns null (fallback)',
      build: () {
        when(
          () => repo.getRoutePolyline(
            startLat: any(named: 'startLat'),
            startLng: any(named: 'startLng'),
            endLat: any(named: 'endLat'),
            endLng: any(named: 'endLng'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => repo.getRideStatusUpdate(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('error')));
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
        );
        await Future.delayed(const Duration(milliseconds: 2200));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );
  });
}
