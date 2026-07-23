import 'package:driver_services/driver_services.dart' as ps;

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<void> resetPassword({
    required String email,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ps.AuthRemoteDataSource _authRemoteDataSource;

  AuthRemoteDataSourceImpl(this._authRemoteDataSource);

  @override
  Future<Map<String, dynamic>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    final result = await _authRemoteDataSource.authenticateDriver(
      email: email,
      password: password,
    );
    return result;
  }

  @override
  Future<void> resetPassword({
    required String email,
  }) async {
    await _authRemoteDataSource.forgotPassword(email: email);
  }
}
