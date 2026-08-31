import 'package:maps/maps.dart';
import 'package:equatable/equatable.dart';

sealed class DriverLocationAccessViewState extends Equatable {
  const DriverLocationAccessViewState();

  @override
  List<Object?> get props => const [];
}

final class DriverLocationAccessChecking extends DriverLocationAccessViewState {
  const DriverLocationAccessChecking();
}

final class DriverLocationAccessReady extends DriverLocationAccessViewState {
  const DriverLocationAccessReady();
}

final class DriverLocationAccessUnavailable
    extends DriverLocationAccessViewState {
  const DriverLocationAccessUnavailable({
    required this.accessState,
    this.message,
  });

  final LocationAccessState accessState;
  final String? message;

  @override
  List<Object?> get props => [accessState, message];
}
