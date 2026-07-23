import 'package:passenger_services/passenger_services.dart' as ps;

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<bool> verifyOtp({
    required String email,
    required String code,
  });

  Future<bool> resetPassword({
    required String email,
  });

  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ps.AuthRemoteDataSource _authRemoteDataSource;

  AuthRemoteDataSourceImpl(this._authRemoteDataSource);

  @override
  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  }) async {
    final result = await _authRemoteDataSource.loginPassenger(
      email: email,
      password: password,
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final result = await _authRemoteDataSource.registerPassenger(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    return result;
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    return _authRemoteDataSource.verifyOtp(email: email, code: code);
  }

  @override
  Future<bool> resetPassword({
    required String email,
  }) async {
    return _authRemoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<bool> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return _authRemoteDataSource.confirmResetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}
