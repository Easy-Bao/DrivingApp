import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';

class InboxCubit({required this.inboxRepository}) extends Cubit<InboxState> {
  static const _pageSize = 50;

  final InboxRepository inboxRepository;
  final List<InboxNotification> _localNotifications = [];
  final Set<String> _dismissedNotificationIds = {};
  String? _activePassengerId;
  int _sessionRevision = 0;
  int _listGeneration = 0;
  int? _markAllReadRevision;
  final Set<String> _readNotificationIds = {};
  Future<void>? _activeLoad;
  String? _activeLoadPassengerId;

  this : super(const InboxInitialState());

  Future<void> loadNotifications(String passengerId) async {
    final activeLoad = _activeLoad;
    if (activeLoad != null && _activeLoadPassengerId == passengerId) {
      await activeLoad;
      return;
    }

    final load = _loadNotifications(passengerId);
    _activeLoad = load;
    _activeLoadPassengerId = passengerId;
    try {
      await load;
    } finally {
      if (identical(_activeLoad, load)) {
        _activeLoad = null;
        _activeLoadPassengerId = null;
      }
    }
  }

  Future<void> _loadNotifications(String passengerId) async {
    if (_activePassengerId != passengerId) {
      _activePassengerId = passengerId;
      _sessionRevision++;
      _markAllReadRevision = null;
      _readNotificationIds.clear();
      _localNotifications.clear();
      _dismissedNotificationIds.clear();
    }
    final requestRevision = _sessionRevision;
    final requestGeneration = ++_listGeneration;
    if (state is! InboxLoadedState) {
      emit(const InboxLoadingState());
    }
    final result = await _fetchPage(passengerId, offset: 0);
    if (isClosed ||
        requestRevision != _sessionRevision ||
        requestGeneration != _listGeneration) {
      return;
    }

    switch (result) {
      case Err(:final failure):
        emit(InboxErrorState(ErrorHandler.getErrorMessage(failure)));
      case Ok(value: final page):
        _emitLoaded(
          InboxLoadedState(
            _mergeLocalNotifications(page.items),
            hasMore: page.hasMore,
            nextOffset: page.nextOffset,
          ),
        );
    }
  }

  Future<void> loadMoreNotifications() async {
    final current = state;
    final passengerId = _activePassengerId;
    if (current is! InboxLoadedState ||
        passengerId == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    final nextOffset = current.nextOffset;
    if (nextOffset == null) return;

    final requestRevision = _sessionRevision;
    final requestGeneration = _listGeneration;
    _emitLoaded(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    final result = await _fetchPage(passengerId, offset: nextOffset);
    if (isClosed ||
        requestRevision != _sessionRevision ||
        requestGeneration != _listGeneration) {
      return;
    }

    final latest = switch (state) {
      final InboxLoadedState loaded => loaded,
      _ => current,
    };
    switch (result) {
      case Err(:final failure):
        _emitLoaded(
          latest.copyWith(
            isLoadingMore: false,
            loadMoreError: ErrorHandler.getErrorMessage(failure),
          ),
        );
      case Ok(value: final page):
        _emitLoaded(
          latest.copyWith(
            notifications: [...latest.notifications, ...page.items],
            hasMore: page.hasMore,
            nextOffset: page.nextOffset,
            isLoadingMore: false,
            clearLoadMoreError: true,
          ),
        );
    }
  }

  Future<Result<OffsetPage<InboxNotification>, Failure>> _fetchPage(
    String passengerId, {
    required int offset,
  }) async {
    if (inboxRepository
        case final PaginatedInboxRepository paginatedRepository) {
      return paginatedRepository.fetchPassengerNotificationsPage(
        passengerId,
        limit: _pageSize,
        offset: offset,
      );
    }
    final result = await inboxRepository.fetchPassengerNotifications(
      passengerId,
    );
    return result.map(
      (notifications) => OffsetPage<InboxNotification>(
        items: notifications,
        hasMore: false,
        nextOffset: null,
      ),
    );
  }

  void _emitLoaded(InboxLoadedState value) {
    if (isClosed) return;
    emit(
      value.copyWith(
        notifications: _mergeLocalNotifications(value.notifications),
        isMarkingAllRead: _markAllReadRevision == _sessionRevision,
      ),
    );
  }

  Future<void> markAllNotificationsAsRead() async {
    final current = state;
    final passengerId = _activePassengerId;
    final revision = _sessionRevision;
    if (current is! InboxLoadedState ||
        passengerId == null ||
        _markAllReadRevision == revision ||
        !current.notifications.any((item) => !item.isRead)) {
      return;
    }
    final requestedIds = current.notifications.map((item) => item.id).toSet();
    _markAllReadRevision = revision;
    _emitLoaded(current.copyWith(clearMarkAllReadError: true));
    final result = await inboxRepository.markAllPassengerNotificationsAsRead(
      passengerId,
    );
    if (isClosed || revision != _sessionRevision) return;
    _markAllReadRevision = null;
    switch (result) {
      case Err(:final failure):
        if (state case final InboxLoadedState latest) {
          _emitLoaded(
            latest.copyWith(
              markAllReadError: switch (ErrorHandler.getAppFailure(failure)) {
                AppFailure(type: ErrorType.server || ErrorType.unknown) =>
                  'Couldn’t mark notifications as read. Try again.',
                final appFailure => appFailure.userMessage,
              },
            ),
          );
        }
      case Ok():
        _readNotificationIds.addAll(requestedIds);
        if (state case final InboxLoadedState latest) {
          _emitLoaded(latest.copyWith(clearMarkAllReadError: true));
        }
    }
  }

  void addLocalNotification(InboxNotification notification) {
    _localNotifications.removeWhere((item) => item.id == notification.id);
    _localNotifications.insert(0, notification);
    final current = state;
    final (
      currentNotifications,
      hasMore,
      nextOffset,
      isLoadingMore,
      loadMoreError,
      markAllReadError,
      dismissError,
    ) = switch (current) {
      InboxLoadedState(
        :final notifications,
        :final hasMore,
        :final nextOffset,
        :final isLoadingMore,
        :final loadMoreError,
        :final markAllReadError,
        :final dismissError,
      ) =>
        (
          notifications,
          hasMore,
          nextOffset,
          isLoadingMore,
          loadMoreError,
          markAllReadError,
          dismissError,
        ),
      _ => (const <InboxNotification>[], false, null, false, null, null, null),
    };
    _emitLoaded(
      InboxLoadedState(
        _mergeLocalNotifications(currentNotifications),
        hasMore: hasMore,
        nextOffset: nextOffset,
        isLoadingMore: isLoadingMore,
        loadMoreError: loadMoreError,
        markAllReadError: markAllReadError,
        dismissError: dismissError,
      ),
    );
  }

  List<InboxNotification> _mergeLocalNotifications(
    List<InboxNotification> remoteNotifications,
  ) {
    final byId = <String, InboxNotification>{};
    for (final remote in remoteNotifications) {
      if (!_dismissedNotificationIds.contains(remote.id)) {
        byId.putIfAbsent(remote.id, () => remote);
      }
    }
    for (final local in _localNotifications.reversed) {
      byId[local.id] = local;
    }
    final notifications = byId.values
        .map(
          (item) => _readNotificationIds.contains(item.id)
              ? item.copyWith(isRead: true)
              : item,
        )
        .toList();
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  void markNotificationAsRead(int index) {
    final current = state;
    if (current is! InboxLoadedState) return;
    if (index < 0 || index >= current.notifications.length) return;
    markNotificationAsReadById(current.notifications[index].id);
  }

  void markNotificationAsReadById(String notificationId) {
    final current = state;
    if (current is! InboxLoadedState) return;
    final index = current.notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0) return;
    final notification = current.notifications[index];
    if (notification.isRead && _readNotificationIds.contains(notificationId)) {
      return;
    }
    _readNotificationIds.add(notificationId);
    final currentList = List<InboxNotification>.from(current.notifications);
    currentList[index] = notification.copyWith(isRead: true);
    _emitLoaded(current.copyWith(notifications: currentList));
  }

  void dismissNotification(int index) {
    final current = state;
    if (current is! InboxLoadedState) return;
    if (index < 0 || index >= current.notifications.length) return;
    dismissNotificationById(current.notifications[index].id);
  }

  void dismissNotificationById(String notificationId) {
    final current = state;
    if (current is! InboxLoadedState) return;
    final index = current.notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0) return;
    final currentList = List<InboxNotification>.from(current.notifications);
    final notification = currentList.removeAt(index);
    final wasLocal = _localNotifications.any(
      (item) => item.id == notification.id,
    );
    _localNotifications.removeWhere((item) => item.id == notification.id);
    _dismissedNotificationIds.add(notification.id);
    _emitLoaded(
      current.copyWith(notifications: currentList, clearDismissError: true),
    );
    unawaited(
      _deleteRemoteNotification(
        notification,
        requestRevision: _sessionRevision,
        wasLocal: wasLocal,
      ),
    );
  }

  Future<void> _deleteRemoteNotification(
    InboxNotification notification, {
    required int requestRevision,
    required bool wasLocal,
  }) async {
    final passengerId = _activePassengerId;
    final notificationId = int.tryParse(notification.id);
    if (passengerId == null || passengerId.isEmpty || notificationId == null) {
      return;
    }
    if (inboxRepository
        case final DismissibleInboxRepository dismissibleRepository) {
      final result = await dismissibleRepository.deletePassengerNotification(
        passengerId,
        notification.id,
      );
      if (isClosed || requestRevision != _sessionRevision) return;
      if (result case Err(:final failure)) {
        _dismissedNotificationIds.remove(notification.id);
        if (wasLocal) {
          _localNotifications.insert(0, notification);
        }
        if (state case final InboxLoadedState latest) {
          _emitLoaded(
            latest.copyWith(
              notifications: [...latest.notifications, notification],
              dismissError: ErrorHandler.getErrorMessage(failure),
            ),
          );
        }
      }
    }
  }

  void clearDismissError() {
    if (state case final InboxLoadedState latest
        when latest.dismissError != null) {
      _emitLoaded(latest.copyWith(clearDismissError: true));
    }
  }

  void clearSessionData() {
    _activePassengerId = null;
    _activeLoad = null;
    _activeLoadPassengerId = null;
    _sessionRevision++;
    _listGeneration++;
    _markAllReadRevision = null;
    _readNotificationIds.clear();
    _localNotifications.clear();
    _dismissedNotificationIds.clear();
    emit(const InboxInitialState());
  }
}
