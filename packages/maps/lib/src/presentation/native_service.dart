import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

import 'package:maps/src/data/datasources/location_remote_data_source.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/failures/place_failure.dart';
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

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  static double calculateHaversine(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double deltaLatitude = _toRadians(latitude2 - latitude1);
    final double deltaLongitude = _toRadians(longitude2 - longitude1);

    final double haversineA =
        math.sin(deltaLatitude / 2.0) * math.sin(deltaLatitude / 2.0) +
        math.cos(_toRadians(latitude1)) *
            math.cos(_toRadians(latitude2)) *
            math.sin(deltaLongitude / 2.0) *
            math.sin(deltaLongitude / 2.0);

    return earthRadiusKm * 2.0 * math.asin(math.sqrt(haversineA));
  }

  Future<double> haversineDistance({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) async {
    return calculateHaversine(
      latitude1,
      longitude1,
      latitude2,
      longitude2,
    );
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
      return Ok([]);
    }
    if (trimmed.length > _maxSearchQueryLength) {
      return Err(const PlaceParseError(message: 'Search query is too long.'));
    }

    try {
      final responseData = await _apiClient.searchPlaces(
        query: trimmed,
        userLatitude: userLatitude ?? proximityLatitude,
        userLongitude: userLongitude ?? proximityLongitude,
      );

      return Ok(_parsePlaces(responseData));
    } on DioException catch (e) {
      dev.log(
        'searchPlaces network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return Err(const PlaceNetworkError());
    } catch (_) {
      dev.log('searchPlaces parse error', name: 'MapNativeService');
      return Err(const PlaceParseError());
    }
  }

  Future<Result<Place, PlaceFailure>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final place = await _apiClient.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      return Ok(place);
    } on DioException catch (e) {
      dev.log(
        'reverseGeocode network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return Err(const PlaceNetworkError());
    } catch (_) {
      dev.log('reverseGeocode parse error', name: 'MapNativeService');
      return Err(const PlaceParseError());
    }
  }

  Future<Result<Route, PlaceFailure>> getRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double latitude, double longitude})> excludePoints = const [],
  }) async {
    try {
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
      final route = await _apiClient.getRoute(body: body);
      return Ok(route);
    } on DioException catch (e) {
      dev.log(
        'getRoute network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return Err(const PlaceNetworkError());
    } catch (_) {
      dev.log('getRoute parse error', name: 'MapNativeService');
      return Err(const PlaceParseError());
    }
  }

  Future<Result<List<double>, PlaceFailure>> getDrivingDistances({
    required double originLatitude,
    required double originLongitude,
    required List<({double latitude, double longitude})> destinations,
  }) async {
    try {
      final response = await _apiClient.getTravelMatrix(
        body: {
          'origin': {'lat': originLatitude, 'lng': originLongitude},
          'destinations': destinations
              .map((point) => {'lat': point.latitude, 'lng': point.longitude})
              .toList(),
        },
      );
      final values = response['distances_km'];
      if (values is! List) {
        return Err(
          const PlaceParseError(message: 'Invalid travel matrix response.'),
        );
      }
      return Ok(
        values.whereType<num>().map((value) => value.toDouble()).toList(),
      );
    } on DioException catch (e) {
      dev.log(
        'getDrivingDistances network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return Err(const PlaceNetworkError());
    } catch (_) {
      dev.log('getDrivingDistances parse error', name: 'MapNativeService');
      return Err(const PlaceParseError());
    }
  }

  Future<Result<List<Place>, PlaceFailure>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) async {
    try {
      final responseData = await _apiClient.getNearbyPois(
        latitude: latitude,
        longitude: longitude,
        page: page,
      );

      return Ok(_parsePlaces(responseData));
    } on DioException catch (e) {
      dev.log(
        'getNearbyPois network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return Err(const PlaceNetworkError());
    } catch (_) {
      dev.log('getNearbyPois parse error', name: 'MapNativeService');
      return Err(const PlaceParseError());
    }
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
