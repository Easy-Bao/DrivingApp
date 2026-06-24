import 'package:passenger_app/core/models/driver/driver_model.dart';
import 'package:passenger_app/features/passenger/data/repositories/driver_repository.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_bloc.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_event.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDriverRepo extends Mock implements DriverRepository {}

FindingDriverBloc _makeBloc(DriverRepository repo) =>
    FindingDriverBloc(repository: repo);

final _mockDriver = const DriverModel(
  id: 'drv_001',
  name: 'Xyrel T.',
  vehicleType: 'Motorcycle',
  plateNumber: 'ZDN-1234',
  rating: 4.9,
  lat: 7.831,
  lng: 123.436,
  distanceKm: 0.42,
  etaMinutes: 2,
  score: 0.95,
);

void main() {
  late MockDriverRepo repo;

  setUp(() => repo = MockDriverRepo());

  group('FindingDriverBloc — initial state', () {
    test('starts as FindingDriverInitial', () async {
      final bloc = _makeBloc(repo);
      expect(bloc.state, isA<FindingDriverInitial>());
      await bloc.close();
    });
  });

  group('FindingDriverBloc — SearchDriversEvent', () {
    blocTest<FindingDriverBloc, FindingDriverState>(
      'emits [Searching, Results] on success',
      build: () {
        when(
          () => repo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => [_mockDriver]);
        return _makeBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const SearchDriversEvent(lat: 7.828282, lng: 123.434343)),
      expect: () => [
        isA<FindingDriverSearching>(),
        FindingDriverResults(drivers: [_mockDriver]),
      ],
    );

    blocTest<FindingDriverBloc, FindingDriverState>(
      'emits [Searching, Results(empty)] on repository error',
      build: () {
        when(
          () => repo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenThrow(Exception('network error'));
        return _makeBloc(repo);
      },
      act: (bloc) =>
          bloc.add(const SearchDriversEvent(lat: 7.828282, lng: 123.434343)),
      expect: () => [
        isA<FindingDriverSearching>(),
        const FindingDriverResults(drivers: []),
      ],
    );
  });

  group('FindingDriverBloc — SelectDriverEvent', () {
    blocTest<FindingDriverBloc, FindingDriverState>(
      'emits FindingDriverSelected with the correct driver',
      build: () => _makeBloc(repo),
      act: (bloc) => bloc.add(SelectDriverEvent(driver: _mockDriver)),
      expect: () => [FindingDriverSelected(selectedDriver: _mockDriver)],
    );
  });

  group('FindingDriverBloc — CancelSearchEvent', () {
    blocTest<FindingDriverBloc, FindingDriverState>(
      'emits FindingDriverCanceled',
      build: () => _makeBloc(repo),
      act: (bloc) => bloc.add(CancelSearchEvent()),
      expect: () => [isA<FindingDriverCanceled>()],
    );
  });
}
