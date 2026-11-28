import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

import 'package:maps/src/data/datasources/location_remote_data_source.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
import 'package:maps/src/domain/geo_math.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

class MapNativeService({
  required Uri placeServiceBaseUri,
  Dio? dio,
  LocationRepository? apiClient,
}) {
  final LocationRepository _apiClient;

  static const _requestTimeout = Duration(seconds: 6);
  static const _maxSearchQueryLength = 256;

  this
    : _apiClient =
          apiClient ??
          LocationRemoteDataSource(
            dio ??
                Dio(
                  BaseOptions(
                    baseUrl: placeServiceBaseUri.toString(),
                    connectTimeout: _requestTimeout,
                    sendTimeout: _requestTimeout,
                    receiveTimeout: _requestTimeout,
                  ),
                ),
          );

  static double calculateHaversine(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) => GeoMath.haversineKm(latitude1, longitude1, latitude2, longitude2);

  Future<double> haversineDistance({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) async {
    return calculateHaversine(latitude1, longitude1, latitude2, longitude2);
  }

  Future<Result<List<Place>, PlaceFailure>> searchPlaces({
    required String query,
    double? proximityLatitude,
    double? proximityLongitude,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const Ok([]);
    }
    if (trimmed.length > _maxSearchQueryLength) {
      return const Err(PlaceParseError(message: 'Search query is too long.'));
    }

    return _runRequest('searchPlaces', () async {
      final responseData = await _apiClient.searchPlaces(
        query: trimmed,
        userLatitude: userLatitude ?? proximityLatitude,
        userLongitude: userLongitude ?? proximityLongitude,
      );
      return _parsePlaces(responseData);
    });
  }

  Future<Result<Place, PlaceFailure>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return _runRequest(
      'reverseGeocode',
      () => _apiClient.reverseGeocode(latitude: latitude, longitude: longitude),
    );
  }

  Future<Result<Route, PlaceFailure>> getRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double latitude, double longitude})> excludePoints = const [],
  }) {
    return _runRequest('getRoute', () async {
      final body = <String, dynamic>{
        'origin': {'lat': originLatitude, 'lng': originLongitude},
        'destination': {
          'lat': destinationLatitude,
          'lng': destinationLongitude,
        },
        'preference': preference.apiValue,
      };
      if (profile != RouteProfile.driving) {
        body['profile'] = profile.apiValue;
      }
      if (excludePoints.isNotEmpty) {
        body['exclude_points'] = excludePoints
            .map((point) => {'lat': point.latitude, 'lng': point.longitude})
            .toList();
      }
      return _apiClient.getRoute(body: body);
    });
  }

  Future<Result<List<double>, PlaceFailure>> getDrivingDistances({
    required double originLatitude,
    required double originLongitude,
    required List<({double latitude, double longitude})> destinations,
  }) async {
    if (destinations.isEmpty) {
      return const Ok([]);
    }

    return _runRequest('getDrivingDistances', () async {
      final response = await _apiClient.getTravelMatrix(
        body: {
          'origin': {'lat': originLatitude, 'lng': originLongitude},
          'destinations': destinations
              .map((point) => {'lat': point.latitude, 'lng': point.longitude})
              .toList(),
        },
      );
      return _parseTravelMatrixDistances(
        response['distances_km'],
        expectedCount: destinations.length,
      );
    });
  }

  Future<Result<List<Place>, PlaceFailure>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) {
    return _runRequest('getNearbyPois', () async {
      final responseData = await _apiClient.getNearbyPois(
        latitude: latitude,
        longitude: longitude,
        page: page,
      );
      return _parsePlaces(responseData);
    });
  }

  Future<Result<T, PlaceFailure>> _runRequest<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return Ok(await action());
    } on DioException catch (e) {
      dev.log(
        '$operation network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      final mapped = FailureMapper.fromException(e);
      return Err(PlaceNetworkError(message: mapped.message));
    } on FormatException catch (e) {
      dev.log('$operation parse error', name: 'MapNativeService');
      return Err(
        PlaceParseError(
          message: e.message.isNotEmpty
              ? e.message
              : 'Failed to parse location response.',
        ),
      );
    } catch (_) {
      dev.log('$operation parse error', name: 'MapNativeService');
      return const Err(PlaceParseError());
    }
  }

  static List<double> _parseTravelMatrixDistances(
    Object? rawDistances, {
    required int expectedCount,
  }) {
    if (rawDistances is! List || rawDistances.length != expectedCount) {
      throw const FormatException('Invalid travel matrix response.');
    }
    final distances = <double>[];
    for (final entry in rawDistances) {
      if (entry is! num) {
        throw const FormatException('Invalid travel matrix response.');
      }
      final value = entry.toDouble();
      if (!value.isFinite || value < 0) {
        throw const FormatException('Invalid travel matrix response.');
      }
      distances.add(value);
    }
    return List<double>.unmodifiable(distances);
  }

  static List<Place> _parsePlaces(Map<String, dynamic> responseData) {
    final rawPlaces = responseData['places'] ?? responseData['results'] ?? [];
    if (rawPlaces is! List) {
      throw const FormatException('Invalid places response.');
    }
    final places = rawPlaces
        .whereType<Map>()
        .map(
          (item) => Place.fromJson(
            decodeObjectMap(item, message: 'Place item is invalid.'),
          ),
        )
        .toList(growable: false);
    if (rawPlaces.isNotEmpty && places.isEmpty) {
      throw const FormatException('Invalid places response.');
    }
    return places;
  }
}
