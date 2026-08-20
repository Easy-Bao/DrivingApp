import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:shared_core/shared_core.dart';

class InboxCubit extends Cubit<InboxState> {
  final IInboxRepository inboxRepository;
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
    final result = await inboxRepository.fetchPassengerNotifications(
      passengerId,
    );
    if (isClosed || requestRevision != _sessionRevision) return;

    result.fold(
      (failure) => emit(InboxErrorState(ErrorHandler.getErrorMessage(failure))),
      (notifications) =>
          emit(InboxLoadedState(_mergeLocalNotifications(notifications))),
    );
  }

  void addLocalNotification(InboxNotification notification) {
    _localNotifications.removeWhere((item) => item.id == notification.id);
    _localNotifications.insert(0, notification);
    final currentNotifications = state is InboxLoadedState
        ? (state as InboxLoadedState).notifications
        : const <InboxNotification>[];
    emit(InboxLoadedState(_mergeLocalNotifications(currentNotifications)));
  }

  List<InboxNotification> _mergeLocalNotifications(
    List<InboxNotification> remoteNotifications,
  ) {
    final notifications = [
      ..._localNotifications,
      ...remoteNotifications.where(
        (remote) => !_localNotifications.any((local) => local.id == remote.id),
      ),
    ];
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  void markNotificationAsRead(int index) {
    if (state is InboxLoadedState) {
      final currentList = List<InboxNotification>.from(
        (state as InboxLoadedState).notifications,
      );
      if (index >= 0 && index < currentList.length) {
        currentList[index] = currentList[index].copyWith(isRead: true);
        emit(InboxLoadedState(currentList));
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
        emit(InboxLoadedState(currentList));
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
