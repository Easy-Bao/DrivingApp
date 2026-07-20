import 'package:driver_services/src/base_api_client.dart';

class PassengerApiService extends BaseApiClient {
  PassengerApiService({required super.baseUrl, super.dio});

  Future<Map<String, dynamic>?> fetchPassengerProfile(
    String passengerId,
  ) async {
    try {
      final response = await clientDio.get('/passengers/$passengerId');
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
