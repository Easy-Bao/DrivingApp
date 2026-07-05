/// Network Error Handler: catches low-level network and socket exceptions and converts them to human-readable error summaries.
library;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class NetworkErrorHandler {
  NetworkErrorHandler._();

  static Future<T> runSafe<T>(
    Future<T> Function() apiCall, {
    String fallbackMessage = 'An unexpected connection error occurred.',
  }) async {
    try {
      return await apiCall();
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Cannot reach the server. Please check your internet connection or if the service is running.',
        originalException: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'Connection failed due to a network isolation/bridge failure.',
        originalException: e,
      );
    } on TimeoutException catch (e) {
      throw NetworkException(
        message: 'The connection request timed out. Please try again.',
        originalException: e,
      );
    } catch (e) {
      throw NetworkException(
        message: '$fallbackMessage ($e)',
        originalException: e,
      );
    }
  }
}

class NetworkException implements Exception {
  final String message;
  final dynamic originalException;

  const NetworkException({required this.message, this.originalException});

  @override
  String toString() => 'NetworkException: $message';
}
