import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_event.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/finding_driver/finding_driver_state.dart';

/// Manages the driver-search lifecycle for the passenger.
class FindingDriverBloc extends Bloc<FindingDriverEvent, FindingDriverState> {
  final DriverRepository _repository;

  FindingDriverBloc({required DriverRepository repository})
    : _repository = repository,
      super(FindingDriverInitial()) {
    on<SearchDriversEvent>(_onSearchDrivers);
    on<SelectDriverEvent>(_onSelectDriver);
    on<CancelSearchEvent>(_onCancelSearch);
  }

  /// Passenger canceled the search.
  void _onCancelSearch(
    CancelSearchEvent event,
    Emitter<FindingDriverState> emit,
  ) {
    emit(FindingDriverCanceled());
  }

  /// Triggers a radar scan — emits [FindingDriverSearching], then [FindingDriverResults].
  Future<void> _onSearchDrivers(
    SearchDriversEvent event,
    Emitter<FindingDriverState> emit,
  ) async {
    emit(FindingDriverSearching());
    try {
      final drivers = await _repository.getNearbyDrivers(
        lat: event.lat,
        lng: event.lng,
      );
      emit(FindingDriverResults(drivers: drivers));
    } catch (_) {
      emit(const FindingDriverResults(drivers: []));
    }
  }

  /// Driver selected from results list.
  void _onSelectDriver(
    SelectDriverEvent event,
    Emitter<FindingDriverState> emit,
  ) {
    emit(FindingDriverSelected(selectedDriver: event.driver));
  }
}
