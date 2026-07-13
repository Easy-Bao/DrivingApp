import 'dart:convert';
import 'package:core_models/core_models.dart';
import 'package:http/http.dart' as http;

abstract class BaseApiClient {
  final Uri baseUrl;

  BaseApiClient({required this.baseUrl});

  Map<String, dynamic> parseMapResponse(
    http.Response response,
    int expectedStatus,
  ) {
    if (response.statusCode == expectedStatus) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (error) {
        throw DataParsingException(
          message: 'Failed to parse response payload: $error',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  List<dynamic> parseListResponse(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      try {
        return jsonDecode(response.body) as List<dynamic>;
      } catch (error) {
        throw DataParsingException(
          message: 'Failed to parse response list: $error',
        );
      }
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  bool parseBoolResponse(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) {
      return true;
    }
    throw ServerException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }
}
