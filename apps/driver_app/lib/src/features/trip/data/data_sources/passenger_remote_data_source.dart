import 'package:dio/dio.dart';

abstract class PassengerRemoteDataSource {
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId);
}

class PassengerRemoteDataSourceImpl implements PassengerRemoteDataSource {
  final Dio _dio;

  PassengerRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchPassengerProfile(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/passengers/$passengerId',
    );
    return response.data ?? {};
  }
}
