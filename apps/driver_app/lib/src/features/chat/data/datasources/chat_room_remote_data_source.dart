import 'package:dio/dio.dart';

abstract class ChatRoomRemoteDataSource {
  Future<bool> initializeRoom({
    required String roomId,
    required String driverId,
    required String passengerId,
  });

  Future<bool> resolveRoom(String roomId);
}

class ChatRoomRemoteDataSourceImpl implements ChatRoomRemoteDataSource {
  final Dio _dio;

  ChatRoomRemoteDataSourceImpl(this._dio);

  @override
  Future<bool> initializeRoom({
    required String roomId,
    required String driverId,
    required String passengerId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chat/rooms',
      data: {
        'roomId': roomId,
        'driverId': driverId,
        'passengerId': passengerId,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> resolveRoom(String roomId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chat/rooms/$roomId/resolve',
    );
    return response.statusCode == 200;
  }
}
