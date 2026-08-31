import 'package:dio/dio.dart';

abstract class PassengerProfileRemoteDataSource {
  Future<Map<String, dynamic>> fetchProfile(String passengerId);

  Future<List<int>> fetchProfileAvatar(String passengerId);

  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  });

  Future<void> uploadProfileAvatar({
    required String passengerId,
    required List<int> bytes,
    required String fileName,
  });
}

class PassengerProfileRemoteDataSourceImpl
    implements PassengerProfileRemoteDataSource {
  final Dio _dio;

  PassengerProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchProfile(String passengerId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}',
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<List<int>> fetchProfileAvatar(String passengerId) async {
    final response = await _dio.get<List<int>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/avatar',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const <int>[];
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String passengerId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}',
      data: data,
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<void> uploadProfileAvatar({
    required String passengerId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    await _dio.post<void>(
      '/api/v1/passengers/${Uri.encodeComponent(passengerId)}/avatar',
      data: formData,
    );
  }
}
