import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/core/location/location.dart';

sealed class LocationAccessViewState extends Equatable {
  const LocationAccessViewState();

  @override
  List<Object?> get props => const [];
}

final class LocationAccessChecking extends LocationAccessViewState {
  const LocationAccessChecking();
}

final class LocationAccessReady extends LocationAccessViewState {
  const LocationAccessReady();
}

final class LocationAccessUnavailable extends LocationAccessViewState {
  const LocationAccessUnavailable({required this.accessState, this.message});

  final LocationAccessState accessState;
  final String? message;

  @override
  List<Object?> get props => [accessState, message];
}
