import 'dart:async';

import 'package:flutter/foundation.dart';
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
    if (state is! InboxLoadedState) {
      emit(const InboxLoadingState());
    }
    final result = await _fetchPage(passengerId, offset: 0);
    if (isClosed || requestRevision != _sessionRevision) return;

    result.fold(
      (failure) => emit(InboxErrorState(ErrorHandler.getErrorMessage(failure))),
      (page) => _emitLoaded(
        InboxLoadedState(
          _mergeLocalNotifications(page.items),
          hasMore: page.hasMore,
          nextOffset: page.nextOffset,
        ),
      ),
    );
  }

  Future<void> loadMoreNotifications() async {
    final current = state;
    final passengerId = _activePassengerId;
    if (current is! InboxLoadedState ||
        passengerId == null ||
        !current.hasMore ||
        current.nextOffset == null ||
        current.isLoadingMore) {
      return;
    }
    final requestRevision = _sessionRevision;
    _emitLoaded(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    final result = await _fetchPage(passengerId, offset: current.nextOffset!);
    if (isClosed || requestRevision != _sessionRevision) return;
    result.fold(
      (failure) => _emitLoaded(
        (state is InboxLoadedState ? state as InboxLoadedState : current)
            .copyWith(
              isLoadingMore: false,
              loadMoreError: ErrorHandler.getErrorMessage(failure),
            ),
      ),
      (page) {
        final latest = state is InboxLoadedState
            ? state as InboxLoadedState
            : current;
        _emitLoaded(
          latest.copyWith(
            notifications: [...latest.notifications, ...page.items],
            hasMore: page.hasMore,
            nextOffset: page.nextOffset,
            isLoadingMore: false,
            clearLoadMoreError: true,
          ),
        );
      },
    );
  }

  Future<Result<OffsetPage<InboxNotification>, Failure>> _fetchPage(
    String passengerId, {
    required int offset,
  }) async {
    final repository = inboxRepository;
    if (repository is PaginatedInboxRepository) {
      final paginatedRepository = repository as PaginatedInboxRepository;
      return paginatedRepository.fetchPassengerNotificationsPage(
        passengerId,
        limit: _pageSize,
        offset: offset,
      );
    }
    final result = await repository.fetchPassengerNotifications(passengerId);
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
    result.fold(
      (failure) {
        final latest = state;
        if (latest is InboxLoadedState) {
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
      },
      (_) {
        _readNotificationIds.addAll(requestedIds);
        final latest = state;
        if (latest is InboxLoadedState) {
          _emitLoaded(latest.copyWith(clearMarkAllReadError: true));
        }
      },
    );
  }

  void addLocalNotification(InboxNotification notification) {
    _localNotifications.removeWhere((item) => item.id == notification.id);
    _localNotifications.insert(0, notification);
    final currentNotifications = state is InboxLoadedState
        ? (state as InboxLoadedState).notifications
        : const <InboxNotification>[];
    final current = state;
    _emitLoaded(
      InboxLoadedState(
        _mergeLocalNotifications(currentNotifications),
        hasMore: current is InboxLoadedState && current.hasMore,
        nextOffset: current is InboxLoadedState ? current.nextOffset : null,
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
    if (state is InboxLoadedState) {
      final currentList = List<InboxNotification>.from(
        (state as InboxLoadedState).notifications,
      );
      if (index >= 0 && index < currentList.length) {
        _readNotificationIds.add(currentList[index].id);
        currentList[index] = currentList[index].copyWith(isRead: true);
        _emitLoaded(
          (state as InboxLoadedState).copyWith(notifications: currentList),
        );
      }
    }
  }

  void dismissNotification(int index) {
    if (state is InboxLoadedState) {
      final currentList = List<InboxNotification>.from(
        (state as InboxLoadedState).notifications,
      );
      if (index >= 0 && index < currentList.length) {
        final notification = currentList[index];
        _localNotifications.removeWhere((item) => item.id == notification.id);
        _dismissedNotificationIds.add(notification.id);
        currentList.removeAt(index);
        _emitLoaded(
          (state as InboxLoadedState).copyWith(notifications: currentList),
        );
        unawaited(_deleteRemoteNotification(notification));
      }
    }
  }

  Future<void> _deleteRemoteNotification(InboxNotification notification) async {
    final passengerId = _activePassengerId;
    final notificationId = int.tryParse(notification.id);
    final repository = inboxRepository;
    if (passengerId == null ||
        passengerId.isEmpty ||
        notificationId == null ||
        repository is! DismissibleInboxRepository) {
      return;
    }

    final dismissibleRepository = repository as DismissibleInboxRepository;
    final result = await dismissibleRepository.deletePassengerNotification(
      passengerId,
      notification.id,
    );
    result.fold(
      (failure) =>
          debugPrint('Inbox notification deletion failed: ${failure.message}'),
      (_) {},
    );
  }

  void clearSessionData() {
    _activePassengerId = null;
    _activeLoad = null;
    _activeLoadPassengerId = null;
    _sessionRevision++;
    _markAllReadRevision = null;
    _readNotificationIds.clear();
    _localNotifications.clear();
    _dismissedNotificationIds.clear();
    emit(const InboxInitialState());
  }
}
