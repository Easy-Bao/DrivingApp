/// Parses the one origin used by the mobile clients for HTTP and WebSocket
/// traffic.
///
/// API paths belong to the individual data sources. Keeping this value to an
/// origin prevents an accidental path, query string, or embedded credential
/// from changing where authenticated requests are sent.
Uri parseApiBaseUri(String rawUrl, {bool allowInsecureHttp = true}) {
  final value = rawUrl.trim();
  Uri? uri;
  try {
    uri = Uri.tryParse(value);
  } on FormatException {
    uri = null;
  }

  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      (!allowInsecureHttp && uri.scheme != 'https') ||
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

/// Resolves the configured API origin for a mobile runtime without allowing
/// platform-specific host rewriting to bypass origin validation.
Uri resolveMobileApiBaseUri({
  required String rawUrl,
  required bool allowInsecureHttp,
  required bool isAndroid,
  required bool isPhysicalDevice,
  required bool usesAdbReverse,
  String? androidEmulatorLoopbackHost,
}) {
  var uri = parseApiBaseUri(rawUrl, allowInsecureHttp: allowInsecureHttp);
  final needsEmulatorHost =
      isAndroid &&
      !isPhysicalDevice &&
      !usesAdbReverse &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1');
  if (!needsEmulatorHost) return uri;

  final loopbackHost = androidEmulatorLoopbackHost?.trim();
  if (loopbackHost == null || loopbackHost.isEmpty) {
    throw const FormatException(
      'ANDROID_EMULATOR_LOOPBACK_HOST is required for local Android URLs.',
    );
  }

  uri = parseApiBaseUri(
    uri.replace(host: loopbackHost).toString(),
    allowInsecureHttp: allowInsecureHttp,
  );
  return uri;
}
