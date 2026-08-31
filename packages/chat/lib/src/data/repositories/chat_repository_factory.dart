import 'package:chat/src/data/data_sources/chat_remote_data_source.dart';
import 'package:chat/src/data/repositories/chat_repository_impl.dart';
import 'package:chat/src/domain/repositories/chat_repository.dart';
import 'package:dio/dio.dart';

abstract interface class ChatRepositoryFactory {
  ChatRepository create({required String currentUserId});
}

final class DefaultChatRepositoryFactory implements ChatRepositoryFactory {
  DefaultChatRepositoryFactory({
    required Dio clientDio,
    required Future<String?> Function() tokenProvider,
  }) : _clientDio = clientDio,
       _tokenProvider = tokenProvider;

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
