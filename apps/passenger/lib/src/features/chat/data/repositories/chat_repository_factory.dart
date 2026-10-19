import 'package:dio/dio.dart';
import 'package:passenger/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:passenger/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:passenger/src/features/chat/domain/repositories/chat_repository.dart';

abstract interface class ChatRepositoryFactory {
  ChatRepository create({required String currentUserId});
}

final class DefaultChatRepositoryFactory({
  required this._httpClient,
  required this._tokenProvider,
  this._refreshTokenProvider,
}) implements ChatRepositoryFactory {
  final Dio _httpClient;
  final Future<String?> Function() _tokenProvider;
  final Future<String?> Function()? _refreshTokenProvider;

  @override
  ChatRepository create({required String currentUserId}) {
    return ChatRepositoryImpl(
      remoteDataSource: ChatRemoteDataSourceImpl(
        tokenProvider: _tokenProvider,
        refreshTokenProvider: _refreshTokenProvider,
      ),
      currentUserId: currentUserId,
      httpClient: _httpClient,
      tokenProvider: _tokenProvider,
    );
  }
}
