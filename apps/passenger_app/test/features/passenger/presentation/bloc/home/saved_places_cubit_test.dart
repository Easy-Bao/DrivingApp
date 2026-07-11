import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/trip_booking/data/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/bloc/home/saved_places_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/bloc/home/saved_places_state.dart';

class MockSavedPlacesRepository extends Mock implements SavedPlacesRepository {}

void main() {
  late MockSavedPlacesRepository mockRepository;

  setUp(() {
    mockRepository = MockSavedPlacesRepository();
  });

  group('SavedPlacesCubit', () {
    test('initial state has isLoading true and empty places', () {
      final cubit = SavedPlacesCubit(repository: mockRepository);
      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.places, isEmpty);
      unawaited(cubit.close());
    });

    blocTest<SavedPlacesCubit, SavedPlacesState>(
      'loadPlaces emits loaded places with isLoading false on success',
      build: () {
        when(() => mockRepository.loadPlaces()).thenAnswer(
          (_) async => [
            {'label': 'Home', 'iconName': 'house'},
            {'label': 'Work', 'iconName': 'briefcase'},
          ],
        );
        return SavedPlacesCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadPlaces(),
      expect: () => [
        const SavedPlacesState(places: [], isLoading: true),
        isA<SavedPlacesState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.places.length, 'places length', 2)
            .having((s) => s.places[0].label, 'first place label', 'Home')
            .having((s) => s.places[1].label, 'second place label', 'Work'),
      ],
    );

    blocTest<SavedPlacesCubit, SavedPlacesState>(
      'loadPlaces handles error and emits isLoading false (or preserves state)',
      build: () {
        when(() => mockRepository.loadPlaces()).thenThrow(Exception('Storage error'));
        return SavedPlacesCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadPlaces(),
      expect: () => [
        const SavedPlacesState(places: [], isLoading: true),
        const SavedPlacesState(places: [], isLoading: false),
      ],
    );
  });
}
