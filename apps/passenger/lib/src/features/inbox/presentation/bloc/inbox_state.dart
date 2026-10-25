import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

sealed class const InboxState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const InboxInitialState() extends InboxState {}

final class const InboxLoadingState() extends InboxState {}

final class const InboxLoadedState(
  this.notifications, {
  this.hasMore = false,
  this.nextOffset,
  this.isLoadingMore = false,
  this.loadMoreError,
  this.isMarkingAllRead = false,
  this.markAllReadError,
}) extends InboxState {
  final List<InboxNotification> notifications;
  final bool hasMore;
  final int? nextOffset;
  final bool isLoadingMore;
  final String? loadMoreError;
  final bool isMarkingAllRead;
  final String? markAllReadError;

  InboxLoadedState copyWith({
    List<InboxNotification>? notifications,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    bool? isMarkingAllRead,
    String? markAllReadError,
    bool clearMarkAllReadError = false,
  }) {
    return InboxLoadedState(
      notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      markAllReadError: clearMarkAllReadError
          ? null
          : markAllReadError ?? this.markAllReadError,
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
    isMarkingAllRead,
    markAllReadError,
  ];
}

final class const InboxErrorState(this.message) extends InboxState {
  final String message;

  @override
  List<Object?> get props => [message];
}
