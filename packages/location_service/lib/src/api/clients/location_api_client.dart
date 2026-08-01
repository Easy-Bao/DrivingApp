import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:location_service/src/api/clients/i_location_api_client.dart';

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
      '/places/search',
      queryParameters: {
        'query': query,
        if (userLat != null) 'userLat': userLat,
        if (userLng != null) 'userLng': userLng,
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
      '/places/reverse',
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
      '/places/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'page': page},
    );
    return response.data ?? {};
  }

  @override
  Future<RouteModel> getRoute({
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/places/route',
      data: body,
    );
    return RouteModel.fromJson(response.data ?? {});
  }
}
