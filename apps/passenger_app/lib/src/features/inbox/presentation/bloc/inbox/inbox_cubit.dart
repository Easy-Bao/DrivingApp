import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/inbox_repository.dart';
import 'package:foundation/foundation.dart';

class InboxCubit extends Cubit<InboxState> {
  static const _pageSize = 50;

  final InboxRepository inboxRepository;
  final List<InboxNotification> _localNotifications = [];
  String? _activePassengerId;
  int _sessionRevision = 0;

  InboxCubit({required this.inboxRepository})
    : super(const InboxInitialState());

  Future<void> loadNotifications(String passengerId) async {
    if (_activePassengerId != passengerId) {
      _activePassengerId = passengerId;
      _sessionRevision++;
      _localNotifications.clear();
    }
    final requestRevision = _sessionRevision;
    if (state is! InboxLoadedState) {
      emit(const InboxLoadingState());
    }
    final result = await _fetchPage(passengerId, offset: 0);
    if (isClosed || requestRevision != _sessionRevision) return;

    result.fold(
      (failure) => emit(InboxErrorState(ErrorHandler.getErrorMessage(failure))),
      (page) => emit(
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
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    final result = await _fetchPage(passengerId, offset: current.nextOffset!);
    if (isClosed || requestRevision != _sessionRevision) return;
    result.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (page) => emit(
        InboxLoadedState(
          _mergeLocalNotifications([...current.notifications, ...page.items]),
          hasMore: page.hasMore,
          nextOffset: page.nextOffset,
        ),
      ),
    );
  }

  Future<Either<Failure, OffsetPage<InboxNotification>>> _fetchPage(
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

  void addLocalNotification(InboxNotification notification) {
    _removeExpiredLocalNotifications();
    if (notification.isExpired) return;
    _localNotifications.removeWhere((item) => item.id == notification.id);
    _localNotifications.insert(0, notification);
    final currentNotifications = state is InboxLoadedState
        ? (state as InboxLoadedState).notifications
        : const <InboxNotification>[];
    final current = state;
    emit(
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
    _removeExpiredLocalNotifications();
    final byId = <String, InboxNotification>{};
    for (final remote in remoteNotifications) {
      if (!remote.isExpired) byId.putIfAbsent(remote.id, () => remote);
    }
    for (final local in _localNotifications.reversed) {
      byId[local.id] = local;
    }
    final notifications = byId.values.toList();
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  void _removeExpiredLocalNotifications() {
    _localNotifications.removeWhere((notification) => notification.isExpired);
  }

  void markNotificationAsRead(int index) {
    if (state is InboxLoadedState) {
      final currentList = List<InboxNotification>.from(
        (state as InboxLoadedState).notifications,
      );
      if (index >= 0 && index < currentList.length) {
        currentList[index] = currentList[index].copyWith(isRead: true);
        emit((state as InboxLoadedState).copyWith(notifications: currentList));
      }
    }
  }

  void dismissNotification(int index) {
    if (state is InboxLoadedState) {
      final currentList = List<InboxNotification>.from(
        (state as InboxLoadedState).notifications,
      );
      if (index >= 0 && index < currentList.length) {
        _localNotifications.removeWhere(
          (item) => item.id == currentList[index].id,
        );
        currentList.removeAt(index);
        emit((state as InboxLoadedState).copyWith(notifications: currentList));
      }
    }
  }

  void clearSessionData() {
    _activePassengerId = null;
    _sessionRevision++;
    _localNotifications.clear();
    emit(const InboxInitialState());
  }
}
