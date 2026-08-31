import 'package:foundation/foundation.dart';

class ChatRoomLockedFailure extends Failure {
  const ChatRoomLockedFailure()
    : super('This chat has already been resolved.');
}
