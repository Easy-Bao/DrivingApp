import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';

sealed class const InboxState() extends Equatable {
  @override
  List<Object?> get props => [];
}

class const InboxInitialState() extends InboxState {}

class const InboxLoadingState() extends InboxState {}

class const InboxLoadedState(
  this.notifications, {
  this.hasMore = false,
  this.nextOffset,
  this.isLoadingMore = false,
  this.loadMoreError,
}) extends InboxState {
  final List<InboxNotification> notifications;
  final bool hasMore;
  final int? nextOffset;
  final bool isLoadingMore;
  final String? loadMoreError;

  InboxLoadedState copyWith({
    List<InboxNotification>? notifications,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return InboxLoadedState(
      notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    hasMore,
    nextOffset,
    isLoadingMore,
    loadMoreError,
  ];
}

class const InboxErrorState(this.message) extends InboxState {
  final String message;

  @override
  List<Object?> get props => [message];
}
