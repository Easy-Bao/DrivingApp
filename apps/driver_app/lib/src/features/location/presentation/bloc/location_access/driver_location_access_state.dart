import 'package:maps/maps.dart';
import 'package:equatable/equatable.dart';

sealed class const DriverLocationAccessViewState() extends Equatable {
  @override
  List<Object?> get props => const [];
}

final class const DriverLocationAccessChecking()
    extends DriverLocationAccessViewState {}

final class const DriverLocationAccessReady()
    extends DriverLocationAccessViewState {}

final class const DriverLocationAccessUnavailable({
  required this.accessState,
  this.message,
}) extends DriverLocationAccessViewState {
  final LocationAccessState accessState;
  final String? message;

  @override
  List<Object?> get props => [accessState, message];
}
