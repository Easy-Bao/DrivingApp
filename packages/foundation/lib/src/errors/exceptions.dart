import 'package:foundation/src/errors/network_diagnostic.dart';

class ServerException implements Exception {
  const ServerException({
    required this.statusCode,
    required this.message,
    this.diagnostic,
  });

  final int statusCode;
  final String message;
  final NetworkErrorDiagnostic? diagnostic;

  @override
  String toString() => 'ServerException ($statusCode): $message';
}

class CacheException implements Exception {
  const CacheException({required this.message});

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class DataParsingException implements Exception {
  const DataParsingException({required this.message});

  final String message;

  @override
  String toString() => 'DataParsingException: $message';
}

class NetworkCircuitOpenException implements Exception {
  const NetworkCircuitOpenException({
    this.category = NetworkErrorCategory.connectionError,
  });

  final NetworkErrorCategory category;

  @override
  String toString() =>
      'NetworkCircuitOpenException: API circuit is open ($category)';
}

/// A missing or invalid client configuration value. [message] names the
/// offending key and how to fix it; it must never contain the value itself.
class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}
