import 'package:dio/dio.dart';
import 'package:passenger_services/src/core/network/base_api_client.dart';
import 'package:session_service/session_service.dart';

class PassengerRemoteDataSource extends BaseApiClient {
  final SecureSessionService _sessionService;

  PassengerRemoteDataSource({
    required super.baseUrl,
    required SecureSessionService sessionService,
    super.dio,
  }) : _sessionService = sessionService;

  Future<Map<String, dynamic>> getPassengerProfile(String passengerId) async {
    final requestHeaders = await _getRequestHeaders();
    final response = await clientDio.get(
      '/passengers/$passengerId',
      options: Options(headers: requestHeaders),
    );
    return parseMapResponse(response, 200);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    final requestHeaders = await _getRequestHeaders();
    final response = await clientDio.put(
      '/passengers/$id',
      options: Options(headers: requestHeaders),
      data: {'name': name, 'phone': phone, 'email': email},
    );
    return parseMapResponse(response, 200);
  }

  Future<List<dynamic>> fetchRideHistory(String passengerId) async {
    final requestHeaders = await _getRequestHeaders();
    final response = await clientDio.get(
      '/passengers/$passengerId/rides',
      options: Options(headers: requestHeaders),
    );
    return parseListResponse(response, 200);
  }

  Future<List<dynamic>> fetchNotifications(String passengerId) async {
    final requestHeaders = await _getRequestHeaders();
    final response = await clientDio.get(
      '/passengers/$passengerId/notifications',
      options: Options(headers: requestHeaders),
    );
    return parseListResponse(response, 200);
  }

  Future<Map<String, String>> _getRequestHeaders() async {
    final String jsonWebToken = await _sessionService.readAuthToken() ?? '';
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    if (jsonWebToken.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $jsonWebToken';
    }
    return requestHeaders;
  }
}
