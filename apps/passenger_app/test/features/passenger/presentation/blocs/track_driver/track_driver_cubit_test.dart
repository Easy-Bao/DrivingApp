import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/track_driver/track_driver_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTrackRepo extends Mock implements TrackRepository {}

class MockPassengerApiService extends Mock implements PassengerApiService {}

TrackDriverCubit _makeCubit(TrackRepository repo, PassengerApiService api) =>
    TrackDriverCubit(repository: repo, apiService: api);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTrackRepo repo;
  late MockPassengerApiService mockApiService;

  setUp(() {
    repo = MockTrackRepo();
    mockApiService = MockPassengerApiService();
    SharedPreferences.setMockInitialValues({});
  });

  group('TrackDriverCubit — initial state', () {
    test('starts with TrackDriverInitial', () async {
      final cubit = _makeCubit(repo, mockApiService);
      expect(cubit.state, isA<TrackDriverInitial>());
      await cubit.close();
    });
  });

  group('TrackDriverCubit — cancelTrip()', () {
    blocTest<TrackDriverCubit, TrackDriverState>(
      'emits TrackDriverCanceled',
      build: () {
        when(
          () => mockApiService.updateRideStatus(any(), any()),
        ).thenAnswer((_) async => true);
        return _makeCubit(repo, mockApiService);
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
          () => mockApiService.getRideStatus(any()),
        ).thenAnswer((_) async => null);
        return _makeCubit(repo, mockApiService);
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
          () => mockApiService.getRideStatus(any()),
        ).thenAnswer((_) async => null);
        return _makeCubit(repo, mockApiService);
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
