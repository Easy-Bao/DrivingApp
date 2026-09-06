import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/home/domain/repositories/public_driver_summary_repository.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';

class PublicDriverSummaryCubit({required this._repository})
    extends Cubit<PublicDriverSummaryState> {
  final PublicDriverSummaryRepository _repository;
  bool _hasLoaded = false;
  Future<void>? _loadInFlight;

  this : super(const PublicDriverSummaryState());

  Future<void> load({bool force = false}) async {
    final existingLoad = _loadInFlight;
    if (existingLoad != null) {
      await existingLoad;
      return;
    }
    if (_hasLoaded && !force) return;

    late final Future<void> request;
    request = _loadOnce().whenComplete(() {
      if (identical(_loadInFlight, request)) {
        _loadInFlight = null;
      }
    });
    _loadInFlight = request;
    await request;
  }

  Future<void> _loadOnce() async {
    if (isClosed) return;
    emit(state.copyWith(status: PublicDriverSummaryStatus.loading));

    try {
      final result = await _repository.fetchSummaries();
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: PublicDriverSummaryStatus.failure,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        ),
        (summaries) {
          _hasLoaded = true;
          emit(
            state.copyWith(
              status: PublicDriverSummaryStatus.success,
              summaries: summaries,
              errorMessage: null,
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PublicDriverSummaryStatus.failure,
          errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
        ),
      );
    }
  }
}
