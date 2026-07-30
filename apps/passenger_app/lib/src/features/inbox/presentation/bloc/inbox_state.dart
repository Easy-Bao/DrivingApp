import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';

part 'generated/inbox_state.freezed.dart';

@freezed
sealed class InboxState with _$InboxState {
  const factory InboxState.initial() = InboxInitialState;
  const factory InboxState.loading() = InboxLoadingState;
  const factory InboxState.loaded(List<InboxNotification> notifications) =
      InboxLoadedState;
  const factory InboxState.error(String message) = InboxErrorState;
}
