/// Parses the one origin used by the mobile clients for HTTP and WebSocket
/// traffic.
///
/// API paths belong to the individual data sources. Keeping this value to an
/// origin prevents an accidental path, query string, or embedded credential
/// from changing where authenticated requests are sent.
Uri parseApiBaseUri(String rawUrl) {
  final value = rawUrl.trim();
  Uri? uri;
  try {
    uri = Uri.tryParse(value);
  } on FormatException {
    uri = null;
  }

  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.host == '0.0.0.0' ||
      uri.host == '::' ||
      uri.host == '*') {
    throw const FormatException(
      'API_BASE_URL must be an HTTP(S) origin without credentials or a path.',
    );
  }

  return uri.replace(path: '');
}
