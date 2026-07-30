import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:location_service/src/features/map/domain/failures/place_failure.dart';
import 'package:location_service/src/features/map/domain/repositories/map_native_service.dart';

class MapNativeServiceImpl implements MapNativeService {
  final Dio _clientDio;
  final Uri _placeServiceBaseUri;

  MapNativeServiceImpl({
    required Uri placeServiceBaseUri,
    Dio? dio,
  })  : _placeServiceBaseUri = placeServiceBaseUri,
        _clientDio = dio ?? Dio();

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

  @override
  Future<double> haversineDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) async {
    return calculateHaversine(lat1, lng1, lat2, lng2);
  }

  @override
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
      final queryParams = <String, String>{
        'query': trimmed,
      };
      if (proximityLat != null) queryParams['proximityLat'] = '$proximityLat';
      if (proximityLng != null) queryParams['proximityLng'] = '$proximityLng';
      if (userLat != null) queryParams['userLat'] = '$userLat';
      if (userLng != null) queryParams['userLng'] = '$userLng';

      final Uri uri = _placeServiceBaseUri.replace(
        path: '${_placeServiceBaseUri.path}/places/search',
        queryParameters: queryParams,
      );

      final response = await _clientDio.getUri(
        uri,
        options: Options(sendTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        return left(PlaceFailure.serverError(
          statusCode: response.statusCode ?? 500,
          message: response.statusMessage,
        ));
      }

      final dynamic responseData = response.data;
      final List<dynamic> dataList = (responseData is List)
          ? responseData
          : (responseData is Map<String, dynamic>
              ? (responseData['places'] ?? responseData['results'] ?? [])
                  as List<dynamic>
              : []);

      final places = dataList
          .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return right(places);
    } on DioException catch (e) {
      dev.log('searchPlaces network failure',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.networkError(message: e.message));
    } catch (e) {
      dev.log('searchPlaces parse error',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.parseError(message: e.toString()));
    }
  }

  @override
  Future<Either<PlaceFailure, PlaceModel>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final Uri uri = _placeServiceBaseUri.replace(
        path: '${_placeServiceBaseUri.path}/places/reverse',
        queryParameters: {
          'lat': '$lat',
          'lng': '$lng',
        },
      );

      final response = await _clientDio.getUri(
        uri,
        options: Options(sendTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        return left(PlaceFailure.serverError(
          statusCode: response.statusCode ?? 500,
          message: response.statusMessage,
        ));
      }

      final place = PlaceModel.fromJson(response.data as Map<String, dynamic>);
      return right(place);
    } on DioException catch (e) {
      dev.log('reverseGeocode network failure',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.networkError(message: e.message));
    } catch (e) {
      dev.log('reverseGeocode parse error',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.parseError(message: e.toString()));
    }
  }

  @override
  Future<Either<PlaceFailure, RouteModel>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final Uri uri = _placeServiceBaseUri.replace(
        path: '${_placeServiceBaseUri.path}/places/route',
      );

      final response = await _clientDio.postUri(
        uri,
        data: {
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        },
        options: Options(sendTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        return left(PlaceFailure.serverError(
          statusCode: response.statusCode ?? 500,
          message: response.statusMessage,
        ));
      }

      final route = RouteModel.fromJson(response.data as Map<String, dynamic>);
      return right(route);
    } on DioException catch (e) {
      dev.log('getRoute network failure',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.networkError(message: e.message));
    } catch (e) {
      dev.log('getRoute parse error',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.parseError(message: e.toString()));
    }
  }

  @override
  Future<Either<PlaceFailure, List<PlaceModel>>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    try {
      final Uri uri = _placeServiceBaseUri.replace(
        path: '${_placeServiceBaseUri.path}/places/nearby',
        queryParameters: {
          'lat': '$lat',
          'lng': '$lng',
          'page': '$page',
        },
      );

      final response = await _clientDio.getUri(
        uri,
        options: Options(sendTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        return left(PlaceFailure.serverError(
          statusCode: response.statusCode ?? 500,
          message: response.statusMessage,
        ));
      }

      final dynamic responseData = response.data;
      final List<dynamic> dataList = (responseData is List)
          ? responseData
          : (responseData is Map<String, dynamic>
              ? (responseData['places'] ?? responseData['results'] ?? [])
                  as List<dynamic>
              : []);

      final places = dataList
          .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return right(places);
    } on DioException catch (e) {
      dev.log('getNearbyPois network failure',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.networkError(message: e.message));
    } catch (e) {
      dev.log('getNearbyPois parse error',
          name: 'MapNativeServiceImpl', error: e);
      return left(PlaceFailure.parseError(message: e.toString()));
    }
  }
}
