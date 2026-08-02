import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/src/api/clients/location_api_client.dart';
import 'package:location_service/src/errors/place_failure.dart';

class MapNativeService {
  final LocationApiClient _apiClient;

  MapNativeService({
    required Uri placeServiceBaseUri,
    Dio? dio,
    LocationApiClient? apiClient,
  }) : _apiClient =
           apiClient ??
           LocationApiClient(
             dio ?? Dio(BaseOptions(baseUrl: placeServiceBaseUri.toString())),
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
  }) async {
    try {
      final route = await _apiClient.getRoute(
        body: {
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        },
      );
      return right(route);
    } on DioException catch (e) {
      dev.log('getRoute network failure', name: 'MapNativeService', error: e);
      return left(PlaceNetworkError(message: e.message));
    } catch (e) {
      dev.log('error', name: 'MapNativeService', error: e);
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
