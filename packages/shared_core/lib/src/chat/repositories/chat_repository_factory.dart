import 'package:dio/dio.dart';
import 'package:shared_core/src/chat/data_sources/chat_remote_data_source.dart';
import 'package:shared_core/src/chat/repositories/chat_repository.dart';
import 'package:shared_core/src/chat/repositories/i_chat_repository.dart';

abstract interface class IChatRepositoryFactory {
  IChatRepository create({required String currentUserId});
}

class ChatRepositoryFactory implements IChatRepositoryFactory {
  ChatRepositoryFactory({
    required Dio clientDio,
    required Future<String?> Function() tokenProvider,
  }) : _clientDio = clientDio,
       _tokenProvider = tokenProvider;

  final Dio _clientDio;
  final Future<String?> Function() _tokenProvider;

  @override
  IChatRepository create({required String currentUserId}) {
    return ChatRepository(
      remoteDataSource: WebSocketChatRemoteDataSource(),
      currentUserId: currentUserId,
      clientDio: _clientDio,
      tokenProvider: _tokenProvider,
    );
  }
}
