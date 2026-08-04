class ServerException implements Exception {
  final int statusCode;
  final String message;

  ServerException({required this.statusCode, required this.message});

  @override
  String toString() => 'ServerException ($statusCode): $message';
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class DataParsingException implements Exception {
  final String message;

  DataParsingException({required this.message});

  @override
  String toString() => 'DataParsingException: $message';
}
