/// Low-level data-source exception thrown when backend services fail.
class ServerException implements Exception {
  final int statusCode;
  final String message;

  ServerException({required this.statusCode, required this.message});

  @override
  String toString() => 'ServerException ($statusCode): $message';
}

/// Low-level exception thrown when local key-value store operations fail.
class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// Low-level exception thrown when payload deserialization or parsing fails.
class DataParsingException implements Exception {
  final String message;

  DataParsingException({required this.message});

  @override
  String toString() => 'DataParsingException: $message';
}
