import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_state.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';

class MockSavedPlacesRepository extends Mock
    implements ISavedPlacesRepository {}

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
          (_) async => <Map<String, dynamic>>[
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
        when(
          () => mockRepository.loadPlaces(),
        ).thenThrow(Exception('Storage error'));
        return SavedPlacesCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadPlaces(),
      expect: () => [
        const SavedPlacesState(places: [], isLoading: true),
        const SavedPlacesState(
          places: [],
          isLoading: false,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      ],
    );

    blocTest<SavedPlacesCubit, SavedPlacesState>(
      'keeps existing shortcuts visible when a refresh fails',
      build: () {
        when(
          () => mockRepository.loadPlaces(),
        ).thenThrow(Exception('Storage error'));
        return SavedPlacesCubit(repository: mockRepository);
      },
      seed: () => const SavedPlacesState(
        places: [
          SavedPlace(
            label: 'Home',
            iconName: 'house',
            latitude: 1,
            longitude: 2,
          ),
        ],
        isLoading: false,
      ),
      act: (cubit) => cubit.loadPlaces(),
      expect: () => [
        isA<SavedPlacesState>()
            .having((state) => state.isLoading, 'is loading', isTrue)
            .having((state) => state.places, 'places', hasLength(1)),
        isA<SavedPlacesState>()
            .having((state) => state.isLoading, 'is loading', isFalse)
            .having((state) => state.places, 'places', hasLength(1))
            .having((state) => state.errorMessage, 'error message', isNotNull),
      ],
    );

    blocTest<SavedPlacesCubit, SavedPlacesState>(
      'replaces a saved shortcut in place instead of removing and re-adding it',
      build: () {
        when(() => mockRepository.savePlaces(any())).thenAnswer((_) async {});
        return SavedPlacesCubit(repository: mockRepository);
      },
      seed: () => const SavedPlacesState(
        places: [
          SavedPlace(
            label: 'Home',
            iconName: 'house',
            latitude: 1,
            longitude: 2,
          ),
          SavedPlace(
            label: 'Work',
            iconName: 'briefcase',
            latitude: 3,
            longitude: 4,
          ),
        ],
        isLoading: false,
      ),
      act: (cubit) => cubit.replacePlace(
        0,
        const SavedPlace(
          label: 'Home',
          iconName: 'house',
          latitude: 5,
          longitude: 6,
          savedAddress: 'Updated home',
        ),
      ),
      expect: () => [
        isA<SavedPlacesState>()
            .having((state) => state.places, 'places', hasLength(2))
            .having(
              (state) => state.places.first.savedAddress,
              'updated first address',
              'Updated home',
            )
            .having(
              (state) => state.places.last.label,
              'second shortcut is retained',
              'Work',
            ),
      ],
      verify: (_) => verify(() => mockRepository.savePlaces(any())).called(1),
    );
  });
}
