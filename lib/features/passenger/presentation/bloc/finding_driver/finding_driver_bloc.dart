import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BaoRide/features/passenger/data/repositories/driver_repository.dart';
import 'finding_driver_event.dart';
import 'finding_driver_state.dart';

class FindingDriverBloc extends Bloc<FindingDriverEvent, FindingDriverState> {
  final DriverRepository _driverRepository;

  FindingDriverBloc({required DriverRepository driverRepository})
      : _driverRepository = driverRepository,
        super(FindingDriverInitial()) {
    on<SearchDriversEvent>(_onSearchDrivers);
    on<SelectDriverEvent>(_onSelectDriver);
    on<CancelSearchEvent>(_onCancelSearch);
  }

  Future<void> _onSearchDrivers(
    SearchDriversEvent event,
    Emitter<FindingDriverState> emit,
  ) async {
    emit(FindingDriverSearching());
    // Simulate searching latency (radar pulse visual check)
    await Future.delayed(const Duration(seconds: 2));
    final drivers = await _driverRepository.getNearbyDrivers(
      lat: event.lat,
      lng: event.lng,
    );
    emit(FindingDriverResults(drivers: drivers));
  }

  void _onSelectDriver(
    SelectDriverEvent event,
    Emitter<FindingDriverState> emit,
  ) {
    emit(FindingDriverSelected(selectedDriver: event.driver));
  }

  void _onCancelSearch(
    CancelSearchEvent event,
    Emitter<FindingDriverState> emit,
  ) {
    emit(FindingDriverCanceled());
  }
}
