import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';

abstract class InboxState extends Equatable {
  const InboxState();

  @override
  List<Object?> get props => [];
}

class InboxInitialState extends InboxState {
  const InboxInitialState();
}

class InboxLoadingState extends InboxState {
  const InboxLoadingState();
}

class InboxLoadedState extends InboxState {
  final List<InboxNotification> notifications;

  const InboxLoadedState(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class InboxErrorState extends InboxState {
  final String message;

  const InboxErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
