import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class MapNativeService {
  final LocationApiClient _apiClient;

  static const _requestTimeout = Duration(seconds: 6);

  MapNativeService({
    required Uri placeServiceBaseUri,
    Dio? dio,
    LocationApiClient? apiClient,
  }) : _apiClient =
           apiClient ??
           LocationApiClient(
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

  Future<Either<PlaceFailure, List<PlaceModel>>> searchPlaces({
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

    try {
      final responseData = await _apiClient.searchPlaces(
        query: trimmed,
        userLat: userLat ?? proximityLat,
        userLng: userLng ?? proximityLng,
      );

      final List<dynamic> dataList =
          (responseData['places'] ?? responseData['results'] ?? [])
              as List<dynamic>;

      final places = dataList
          .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return right(places);
    } on DioException catch (e) {
      dev.log(
        'searchPlaces network failure',
        name: 'MapNativeService',
        error: e,
      );
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log('searchPlaces parse error', name: 'MapNativeService', error: e);
      return left(PlaceParseError(message: e.toString()));
    }
  }

  Future<Either<PlaceFailure, PlaceModel>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final place = await _apiClient.reverseGeocode(lat: lat, lng: lng);
      return right(place);
    } on DioException catch (e) {
      dev.log(
        'reverseGeocode network failure',
        name: 'MapNativeService',
        error: e,
      );
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log('error', name: 'MapNativeService', error: e);
      return left(PlaceParseError(message: e.toString()));
    }
  }

  Future<Either<PlaceFailure, RouteModel>> getRoute({
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
      dev.log('getRoute network failure', name: 'MapNativeService', error: e);
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log('error', name: 'MapNativeService', error: e);
      return left(PlaceParseError(message: e.toString()));
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
      final values = response['distancesKm'];
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
        'getDrivingDistances network failure',
        name: 'MapNativeService',
        error: e,
      );
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log(
        'getDrivingDistances parse error',
        name: 'MapNativeService',
        error: e,
      );
      return left(PlaceParseError(message: e.toString()));
    }
  }

  Future<Either<PlaceFailure, List<PlaceModel>>> getNearbyPois({
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

      final List<dynamic> dataList =
          (responseData['places'] ?? responseData['results'] ?? [])
              as List<dynamic>;

      final places = dataList
          .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return right(places);
    } on DioException catch (e) {
      dev.log(
        'getNearbyPois network failure',
        name: 'MapNativeService',
        error: e,
      );
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log('error', name: 'MapNativeService', error: e);
      return left(PlaceParseError(message: e.toString()));
    }
  }
}
