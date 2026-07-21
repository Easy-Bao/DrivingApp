import 'package:driver_services/src/core/network/base_api_client.dart';

abstract class PassengerRemoteDataSource {
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId);
}

class PassengerRemoteDataSourceImpl extends BaseApiClient implements PassengerRemoteDataSource {
  PassengerRemoteDataSourceImpl({required super.baseUrl, super.dio});

  @override
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId) async {
    final response = await clientDio.get('/passengers/$passengerId');
    return parseMapResponse(response, 200);
  }
}
