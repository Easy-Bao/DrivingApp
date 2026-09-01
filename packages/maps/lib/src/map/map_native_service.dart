import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:maps/src/data/data_sources/location_remote_data_source.dart';
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
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double haversineA =
        math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);

    return earthRadiusKm * 2.0 * math.asin(math.sqrt(haversineA));
  }

  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    return calculateHaversine(lat1, lng1, lat2, lng2);
  }

  Future<Either<PlaceFailure, List<Place>>> searchPlaces({
    required String query,
    double? proximityLat,
    double? proximityLng,
    double? userLat,
    double? userLng,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return right([]);
    }
    if (trimmed.length > _maxSearchQueryLength) {
      return left(const PlaceParseError(message: 'Search query is too long.'));
    }

    try {
      final responseData = await _apiClient.searchPlaces(
        query: trimmed,
        userLat: userLat ?? proximityLat,
        userLng: userLng ?? proximityLng,
      );

      return right(_parsePlaces(responseData));
    } on DioException catch (e) {
      dev.log(
        'searchPlaces network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return left(const PlaceNetworkError());
    } catch (_) {
      dev.log('searchPlaces parse error', name: 'MapNativeService');
      return left(const PlaceParseError());
    }
  }

  Future<Either<PlaceFailure, Place>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final place = await _apiClient.reverseGeocode(lat: lat, lng: lng);
      return right(place);
    } on DioException catch (e) {
      dev.log(
        'reverseGeocode network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return left(const PlaceNetworkError());
    } catch (_) {
      dev.log('reverseGeocode parse error', name: 'MapNativeService');
      return left(const PlaceParseError());
    }
  }

  Future<Either<PlaceFailure, Route>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    RoutePreference preference = RoutePreference.fastest,
    RouteProfile profile = RouteProfile.driving,
    List<({double lat, double lng})> excludePoints = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'origin': {'lat': originLat, 'lng': originLng},
        'destination': {'lat': destLat, 'lng': destLng},
        'preference': preference.apiValue,
      };
      if (profile != RouteProfile.driving) {
        body['profile'] = profile.apiValue;
      }
      if (excludePoints.isNotEmpty) {
        body['exclude_points'] = excludePoints
            .map((point) => {'lat': point.lat, 'lng': point.lng})
            .toList();
      }
      final route = await _apiClient.getRoute(body: body);
      return right(route);
    } on DioException catch (e) {
      dev.log(
        'getRoute network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return left(const PlaceNetworkError());
    } catch (_) {
      dev.log('getRoute parse error', name: 'MapNativeService');
      return left(const PlaceParseError());
    }
  }

  Future<Either<PlaceFailure, List<double>>> getDrivingDistances({
    required double originLat,
    required double originLng,
    required List<({double lat, double lng})> destinations,
  }) async {
    try {
      final response = await _apiClient.getTravelMatrix(
        body: {
          'origin': {'lat': originLat, 'lng': originLng},
          'destinations': destinations
              .map((point) => {'lat': point.lat, 'lng': point.lng})
              .toList(),
        },
      );
      final values = response['distances_km'];
      if (values is! List) {
        return left(
          const PlaceParseError(message: 'Invalid travel matrix response.'),
        );
      }
      return right(
        values.whereType<num>().map((value) => value.toDouble()).toList(),
      );
    } on DioException catch (e) {
      dev.log(
        'getDrivingDistances network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return left(const PlaceNetworkError());
    } catch (_) {
      dev.log('getDrivingDistances parse error', name: 'MapNativeService');
      return left(const PlaceParseError());
    }
  }

  Future<Either<PlaceFailure, List<Place>>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    try {
      final responseData = await _apiClient.getNearbyPois(
        lat: lat,
        lng: lng,
        page: page,
      );

      return right(_parsePlaces(responseData));
    } on DioException catch (e) {
      dev.log(
        'getNearbyPois network failure: ${e.type.name}',
        name: 'MapNativeService',
      );
      return left(const PlaceNetworkError());
    } catch (_) {
      dev.log('getNearbyPois parse error', name: 'MapNativeService');
      return left(const PlaceParseError());
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
