import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger_app/src/features/home/domain/repositories/public_driver_summary_repository.dart';
import 'package:foundation/foundation.dart';

class PublicDriverSummaryCubit({
  required PublicDriverSummaryRepository repository,
}) extends Cubit<PublicDriverSummaryState> {
  final PublicDriverSummaryRepository _repository;
  bool _hasLoaded = false;

  this : _repository = repository, super(const PublicDriverSummaryState());

  Future<void> load({bool force = false}) async {
    if (_hasLoaded && !force) return;
    _hasLoaded = true;
    emit(state.copyWith(status: PublicDriverSummaryStatus.loading));

    final result = await _repository.fetchSummaries();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PublicDriverSummaryStatus.failure,
          errorMessage: ErrorHandler.getErrorMessage(failure),
        ),
      ),
      (summaries) => emit(
        state.copyWith(
          status: PublicDriverSummaryStatus.success,
          summaries: summaries,
          errorMessage: null,
        ),
      ),
    );
  }
}
