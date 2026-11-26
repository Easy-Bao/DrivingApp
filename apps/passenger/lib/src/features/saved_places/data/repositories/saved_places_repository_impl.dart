import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/session/storage_keys.dart';
import 'package:passenger/src/features/saved_places/data/dto/saved_place_dto.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SavedPlacesRepositoryImpl implements SavedPlacesRepository {
  SavedPlacesRepositoryImpl({required this._preferences, this._sessionService});

  static const String storageKey = StorageKeys.savedPlaces;

  final SharedPreferences _preferences;
  final SessionStore? _sessionService;

  Future<String?> _resolveStorageKey() async {
    final sessionService = _sessionService;
    if (sessionService == null) return storageKey;
    final passengerId = (await sessionService.readPassengerId())?.trim() ?? '';
    if (passengerId.isEmpty) return null;
    return '${storageKey}_$passengerId';
  }

  @override
  Future<List<SavedPlace>> loadPlaces() async {
    final key = await _resolveStorageKey();
    if (key == null) return const [];
    try {
      var raw = _preferences.getString(key);
      var migratedFromLegacy = false;
      if ((raw == null || raw.trim().isEmpty) && key != storageKey) {
        final legacyRaw = _preferences.getString(storageKey);
        if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
          raw = legacyRaw;
          migratedFromLegacy = true;
        }
      }
      if (raw == null || raw.trim().isEmpty) {
        return const [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        await _preferences.remove(key);
        if (migratedFromLegacy) {
          await _preferences.remove(storageKey);
        }
        return const [];
      }

      final places = <SavedPlace>[];
      var droppedMalformedItem = false;
      for (final item in decoded) {
        if (item is! Map) {
          droppedMalformedItem = true;
          continue;
        }
        try {
          places.add(SavedPlaceDto.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          droppedMalformedItem = true;
        }
      }

      if (migratedFromLegacy || droppedMalformedItem) {
        if (places.isEmpty) {
          await _preferences.remove(key);
        } else {
          await _writeRaw(key, places);
        }
        if (migratedFromLegacy) {
          await _preferences.remove(storageKey);
        }
      }
      return places;
    } catch (_) {
      await _preferences.remove(key);
      return const [];
    }
  }

  @override
  Future<void> savePlaces(List<SavedPlace> places) async {
    final key = await _resolveStorageKey();
    if (key == null) return;
    try {
      await _writeRaw(key, places);
    } catch (_) {
      throw const CacheFailure('Failed to write saved places to storage.');
    }
  }

  Future<void> _writeRaw(String key, List<SavedPlace> places) async {
    final models = places
        .map(
          (p) => SavedPlaceDto(
            label: p.label,
            iconName: p.iconName,
            savedAddress: p.savedAddress,
            latitude: p.latitude,
            longitude: p.longitude,
            isDefault: p.isDefault,
          ),
        )
        .toList();
    await _preferences.setString(key, SavedPlaceDto.encodeList(models));
  }
}
