import 'package:passenger_app/src/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:passenger_app/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:passenger_app/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:dio/dio.dart';

abstract interface class ChatRepositoryFactory {
  ChatRepository create({required String currentUserId});
}

final class DefaultChatRepositoryFactory({
  required Dio clientDio,
  required Future<String?> Function() tokenProvider,
}) implements ChatRepositoryFactory {
  this : _clientDio = clientDio, _tokenProvider = tokenProvider;

  final Dio _clientDio;
  final Future<String?> Function() _tokenProvider;

  @override
  ChatRepository create({required String currentUserId}) {
    return ChatRepositoryImpl(
      remoteDataSource: WebSocketChatRemoteDataSource(),
      currentUserId: currentUserId,
      clientDio: _clientDio,
      tokenProvider: _tokenProvider,
    );
  }
}
