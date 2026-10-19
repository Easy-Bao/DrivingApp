import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

import 'package:maps/src/data/dto/place_dto.dart';
import 'package:maps/src/data/dto/route_dto.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

class LocationRemoteDataSource(this._dio) implements LocationRepository {
  final Dio _dio;

  static final _transientReadOptions = Options(
    extra: {requestRetryPolicyExtraKey: RequestRetryPolicy.transientRead},
  );

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/search',
      queryParameters: {
        'query': query,
        'userLat': ?userLatitude,
        'userLng': ?userLongitude,
      },
      options: _transientReadOptions,
    );
    return response.data ?? {};
  }

  @override
  Future<Place> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/reverse',
      queryParameters: {'lat': latitude, 'lng': longitude},
      options: _transientReadOptions,
    );
    return PlaceDto.fromJson(response.data ?? {}).toDomain();
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double latitude,
    required double longitude,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/nearby',
      queryParameters: {'lat': latitude, 'lng': longitude, 'page': page},
      options: _transientReadOptions,
    );
    return response.data ?? {};
  }

  @override
  Future<Route> getRoute({required Map<String, dynamic> body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/location/route',
      data: body,
      options: _transientReadOptions,
    );
    return RouteDto.fromJson(response.data ?? {}).toDomain();
  }

  @override
  Future<Map<String, dynamic>> getTravelMatrix({
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/location/matrix',
      data: body,
      options: _transientReadOptions,
    );
    return response.data ?? {};
  }
}
