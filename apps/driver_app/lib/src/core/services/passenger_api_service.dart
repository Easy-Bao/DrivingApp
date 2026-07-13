import 'package:http/http.dart' as http;
import 'base_api_client.dart';

class PassengerApiService extends BaseApiClient {
  PassengerApiService({required super.baseUrl});

  Future<Map<String, dynamic>?> fetchPassengerProfile(
    String passengerId,
  ) async {
    try {
      final response = await http.get(
        baseUrl.replace(path: '/passengers/$passengerId'),
        headers: {'Content-Type': 'application/json'},
      );
      return parseMapResponse(response, 200);
    } catch (_) {
      return null;
    }
  }
}
