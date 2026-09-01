class ServerException({required this.statusCode, required this.message})
    implements Exception {
  final int statusCode;
  final String message;

  @override
  String toString() => 'ServerException ($statusCode): $message';
}

class CacheException({required this.message}) implements Exception {
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class DataParsingException({required this.message}) implements Exception {
  final String message;

  @override
  String toString() => 'DataParsingException: $message';
}

class const NetworkCircuitOpenException() implements Exception {
  @override
  String toString() => 'NetworkCircuitOpenException: API circuit is open';
}
