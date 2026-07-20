import 'package:core_models/core_models.dart';
import 'package:passenger_services/passenger_services.dart';

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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final PassengerApiService _passengerApiService;

  AuthRemoteDataSourceImpl(this._passengerApiService);

  @override
  Future<Map<String, dynamic>> loginPassenger({
    required String email,
    required String password,
  }) async {
    final result = await _passengerApiService.loginPassenger(
      email: email,
      password: password,
    );
    if (result == null) {
      throw ServerException(
        statusCode: 401,
        message: 'Invalid email or password',
      );
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final result = await _passengerApiService.registerPassenger(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    if (result == null) {
      throw ServerException(
        statusCode: 400,
        message: 'Registration failed',
      );
    }
    return result;
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    return _passengerApiService.verifyOtp(email: email, code: code);
  }

  @override
  Future<bool> resetPassword({
    required String email,
  }) async {
    return _passengerApiService.forgotPassword(email: email);
  }
}
