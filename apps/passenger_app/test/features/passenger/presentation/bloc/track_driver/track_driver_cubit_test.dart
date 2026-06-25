import 'package:core_models/core_models.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock Repositories

class MockTrackRepo extends Mock implements TrackRepository {}

// Helper Factory Methods

TrackDriverCubit _makeCubit(TrackRepository repo) =>
    TrackDriverCubit(repository: repo);

// Unit Tests

void main() {
  late MockTrackRepo repo;

  setUp(() => repo = MockTrackRepo());

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
      build: () => _makeCubit(repo),
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
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
        );
        // Wait for at least one timer tick
        await Future.delayed(const Duration(milliseconds: 1600));
      },
      expect: () => [
        // At least one InProgress emitted
        isA<TrackDriverInProgress>(),
      ],
      // Allow extra states from the timer
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
        return _makeCubit(repo);
      },
      act: (cubit) async {
        await cubit.startTracking(
          startLat: 7.828,
          startLng: 123.434,
          endLat: 7.830,
          endLng: 123.436,
        );
        await Future.delayed(const Duration(milliseconds: 1600));
      },
      expect: () => [isA<TrackDriverInProgress>()],
      skip: 0,
    );
  });
}
