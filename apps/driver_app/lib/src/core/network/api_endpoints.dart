import 'package:session_service/session_service.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static Uri buildChatWebSocketUri({
    required String roomId,
    required String userId,
    String? token,
  }) {
    final baseUri = EnvironmentConfig.webSocketBaseUri;
    final params = {'roomId': roomId, 'userId': userId};
    if (token != null) {
      params['token'] = token;
    }
    return baseUri.replace(path: '/chat/ws', queryParameters: params);
  }
}
