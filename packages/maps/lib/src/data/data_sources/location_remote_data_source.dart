import 'package:dio/dio.dart';

import 'package:maps/src/data/dto/place_dto.dart';
import 'package:maps/src/data/dto/route_dto.dart';
import 'package:maps/src/domain/entities/place.dart';
import 'package:maps/src/domain/entities/route.dart';
import 'package:maps/src/domain/repositories/location_repository.dart';

class LocationRemoteDataSource(this._dio) implements LocationRepository {
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> searchPlaces({
    required String query,
    double? userLat,
    double? userLng,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/search',
      queryParameters: {
        'query': query,
        'userLat': ?userLat,
        'userLng': ?userLng,
      },
    );
    return response.data ?? {};
  }

  @override
  Future<Place> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/reverse',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return PlaceDto.fromJson(response.data ?? {}).toDomain();
  }

  @override
  Future<Map<String, dynamic>> getNearbyPois({
    required double lat,
    required double lng,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'page': page},
    );
    return response.data ?? {};
  }

  @override
  Future<Route> getRoute({required Map<String, dynamic> body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/location/route',
      data: body,
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
    );
    return response.data ?? {};
  }
}
