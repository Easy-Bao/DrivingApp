import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Entities/InboxNotification.dart';
import 'package:passenger_app/src/Features/Inbox/Domain/Repositories/IInboxRepository.dart';
import 'package:passenger_app/src/Features/Inbox/Presentation/Bloc/InboxState.dart';

class InboxCubit extends Cubit<InboxState> {
  final IInboxRepository inboxRepository;

  InboxCubit({required this.inboxRepository})
    : super(const InboxInitialState());

  Future<void> loadNotifications(String passengerId) async {
    if (state is! InboxLoadedState) {
      emit(const InboxLoadingState());
    }
    final result = await inboxRepository.fetchPassengerNotifications(
      passengerId,
    );

    result.fold(
      (failure) => emit(InboxErrorState(failure.message)),
      (notifications) => emit(InboxLoadedState(notifications)),
    );
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
        currentList.removeAt(index);
        emit(InboxLoadedState(currentList));
      }
    }
  }
}
