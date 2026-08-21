import 'package:dio/dio.dart';

enum ChatRoomInitializationStatus { opened, resolved, unavailable }

abstract class ChatRoomRemoteDataSource {
  Future<ChatRoomInitializationStatus> initializeRoom({
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
  Future<ChatRoomInitializationStatus> initializeRoom({
    required String roomId,
    required String driverId,
    required String passengerId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/chat/rooms',
        data: {
          'roomId': roomId,
          'driverId': driverId,
          'passengerId': passengerId,
        },
      );
      if (response.statusCode == 423) {
        return ChatRoomInitializationStatus.resolved;
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatRoomInitializationStatus.opened;
      }
      return ChatRoomInitializationStatus.unavailable;
    } on DioException catch (error) {
      if (error.response?.statusCode == 423) {
        return ChatRoomInitializationStatus.resolved;
      }
      return ChatRoomInitializationStatus.unavailable;
    } catch (_) {
      return ChatRoomInitializationStatus.unavailable;
    }
  }

  @override
  Future<bool> resolveRoom(String roomId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chat/rooms/${Uri.encodeComponent(roomId)}/resolve',
    );
    return response.statusCode == 200;
  }
}
