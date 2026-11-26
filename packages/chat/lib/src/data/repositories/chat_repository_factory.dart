import 'package:chat/src/data/datasources/chat_remote_data_source.dart';
import 'package:chat/src/data/repositories/chat_repository_impl.dart';
import 'package:chat/src/domain/repositories/chat_repository.dart';
import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

abstract interface class ChatRepositoryFactory {
  ChatRepository create({required String currentUserId});
}

final class DefaultChatRepositoryFactory({
  required this._httpClient,
  required this._tokenProvider,
  this._refreshTokenProvider,
  this._networkAvailability,
}) implements ChatRepositoryFactory {
  final Dio _httpClient;
  final Future<String?> Function() _tokenProvider;
  final Future<String?> Function()? _refreshTokenProvider;
  final NetworkAvailabilityCoordinator? _networkAvailability;

  @override
  ChatRepository create({required String currentUserId}) {
    return ChatRepositoryImpl(
      remoteDataSource: ChatRemoteDataSourceImpl(
        tokenProvider: _tokenProvider,
        refreshTokenProvider: _refreshTokenProvider,
        networkAvailability: _networkAvailability,
      ),
      currentUserId: currentUserId,
      httpClient: _httpClient,
      tokenProvider: _tokenProvider,
    );
  }
}
