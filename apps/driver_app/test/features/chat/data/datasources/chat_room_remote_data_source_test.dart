import 'package:dio/dio.dart';
import 'package:driver_app/src/features/chat/data/datasources/chat_room_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a resolved chat room response to the resolved status', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _StubHttpClientAdapter(
        (_) => ResponseBody.fromString('Room Resolved', 423),
      );
    final dataSource = ChatRoomRemoteDataSourceImpl(dio);

    final result = await dataSource.initializeRoom(
      roomId: 'ride-42',
      driverId: 'driver-7',
      passengerId: 'passenger-9',
    );

    expect(result, ChatRoomInitializationStatus.resolved);
  });

  test('maps a successful room response to the opened status', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _StubHttpClientAdapter(
        (_) => ResponseBody.fromString(
          '{}',
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    final dataSource = ChatRoomRemoteDataSourceImpl(dio);

    final result = await dataSource.initializeRoom(
      roomId: 'ride-42',
      driverId: 'driver-7',
      passengerId: 'passenger-9',
    );

    expect(result, ChatRoomInitializationStatus.opened);
  });
}

class _StubHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _StubHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
