import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/trip/domain/entities/booking_draft.dart';

class BookingDraftState extends Equatable {
  final BookingDraft? draft;

  const BookingDraftState({this.draft});

  bool get hasDraft => draft != null;

  @override
  List<Object?> get props => [draft];
}

class BookingDraftCubit extends Cubit<BookingDraftState> {
  BookingDraftCubit() : super(const BookingDraftState());

  void save(BookingDraft draft) {
    emit(BookingDraftState(draft: draft));
  }

  void clear() {
    emit(const BookingDraftState());
  }
}
