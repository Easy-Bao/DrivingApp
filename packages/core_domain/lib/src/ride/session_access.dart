final class RideSessionAccess {
  const RideSessionAccess(this._authorizationToken);

  final String? _authorizationToken;

  bool get isAuthenticated =>
      _authorizationToken != null && _authorizationToken.trim().isNotEmpty;

  bool executeAuthorizedAction(
    void Function(String token, int sequence) action,
  ) {
    if (_authorizationToken != null && _authorizationToken.trim().isNotEmpty) {
      action(_authorizationToken, 0);
      return true;
    }
    return false;
  }
}
