import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_draft.dart';

class const BookingDraftState({this.draft}) extends Equatable {
  final BookingDraft? draft;

  bool get hasDraft => draft != null;

  @override
  List<Object?> get props => [draft];
}

class BookingDraftCubit() extends Cubit<BookingDraftState> {
  this : super(const BookingDraftState());

  void save(BookingDraft draft) {
    emit(BookingDraftState(draft: draft));
  }

  void clear() {
    emit(const BookingDraftState());
  }
}
