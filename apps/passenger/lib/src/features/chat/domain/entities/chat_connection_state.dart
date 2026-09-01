sealed class const ChatConnectionState() {}

final class const ChatConnecting(this.attempt) extends ChatConnectionState {
  final int attempt;
}

final class const ChatConnected() extends ChatConnectionState {}

final class const ChatDisconnected({this.reconnectIn})
    extends ChatConnectionState {
  final Duration? reconnectIn;
}
