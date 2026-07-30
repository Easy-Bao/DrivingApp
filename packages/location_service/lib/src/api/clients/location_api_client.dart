import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'generated/location_api_client.g.dart';

@RestApi()
abstract class LocationApiClient {
  factory LocationApiClient(Dio dio, {String baseUrl}) = _LocationApiClient;

  @GET('/places/search')
  Future<Map<String, dynamic>> searchPlaces({
    @Query('query') required String query,
    @Query('userLat') double? userLat,
    @Query('userLng') double? userLng,
  });

  @GET('/places/reverse')
  Future<PlaceModel> reverseGeocode({
    @Query('lat') required double lat,
    @Query('lng') required double lng,
  });

  @GET('/places/nearby')
  Future<Map<String, dynamic>> getNearbyPois({
    @Query('lat') required double lat,
    @Query('lng') required double lng,
    @Query('page') int page = 1,
  });

  @POST('/places/route')
  Future<RouteModel> getRoute({
    @Body() required Map<String, dynamic> body,
  });
}
