import 'package:dio/dio.dart';
import 'package:shared_core/shared_core.dart';

class LocationApiClient implements ILocationApiClient {
  final Dio _dio;

  LocationApiClient(this._dio);

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
  Future<PlaceModel> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/location/reverse',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return PlaceModel.fromJson(response.data ?? {});
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
  Future<RouteModel> getRoute({required Map<String, dynamic> body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/location/route',
      data: body,
    );
    return RouteModel.fromJson(response.data ?? {});
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
