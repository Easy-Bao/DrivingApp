import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/saved_places/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSessionStore extends Mock implements SessionStore {}

void main() {
  const storageKey = 'passenger_saved_places_v1';
  late SavedPlacesRepository repository;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    repository = SavedPlacesRepositoryImpl(preferences: preferences);
  });

  test('empty storage is treated as no saved places', () async {
    expect(await repository.loadPlaces(), isEmpty);
  });

  test('malformed storage is cleared instead of shown as an error', () async {
    SharedPreferences.setMockInitialValues({storageKey: '{invalid json'});
    preferences = await SharedPreferences.getInstance();
    repository = SavedPlacesRepositoryImpl(preferences: preferences);

    expect(await repository.loadPlaces(), isEmpty);
    expect(preferences.getString(storageKey), isNull);
  });

  test('saved places survive a write and read round trip', () async {
    await repository.savePlaces(const [
      SavedPlace(
        label: 'Home',
        iconName: 'house',
        savedAddress: 'Mountain View',
        latitude: 14.5995,
        longitude: 120.9842,
        isDefault: true,
      ),
    ]);

    final stored = await repository.loadPlaces();
    expect(stored.single.label, 'Home');
    expect(stored.single.savedAddress, 'Mountain View');
    expect(stored.single.latitude, 14.5995);
    expect(stored.single.isDefault, isTrue);
  });

  test('skips a single malformed item instead of discarding all valid saved places', () async {
    SharedPreferences.setMockInitialValues({
      storageKey: jsonEncode([
        'corrupt-entry',
        {
          'label': 'Home',
          'iconName': 'house',
          'savedAddress': 'Mountain View',
          'latitude': 14.5995,
          'longitude': 120.9842,
          'isDefault': true,
        },
      ]),
    });
    preferences = await SharedPreferences.getInstance();
    repository = SavedPlacesRepositoryImpl(preferences: preferences);

    final stored = await repository.loadPlaces();
    expect(stored, hasLength(1));
    expect(stored.single.label, 'Home');
  });

  test(
    'isolates saved places per passenger id and migrates legacy storage',
    () async {
      SharedPreferences.setMockInitialValues({
        storageKey: jsonEncode([
          {
            'label': 'Home',
            'iconName': 'house',
            'savedAddress': 'Legacy Home',
            'isDefault': true,
          },
        ]),
      });
      preferences = await SharedPreferences.getInstance();
      final sessionStore = _MockSessionStore();
      var currentPassengerId = 'passenger-a';
      when(sessionStore.readPassengerId)
          .thenAnswer((_) async => currentPassengerId);

      final scopedRepo = SavedPlacesRepositoryImpl(
        preferences: preferences,
        sessionService: sessionStore,
      );

      final migrated = await scopedRepo.loadPlaces();
      expect(migrated.single.savedAddress, 'Legacy Home');
      expect(preferences.getString(storageKey), isNull);

      currentPassengerId = 'passenger-b';
      expect(await scopedRepo.loadPlaces(), isEmpty);
    },
  );
}
