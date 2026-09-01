import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

sealed class const LocationAccessViewState() extends Equatable {
  @override
  List<Object?> get props => const [];
}

final class const LocationAccessChecking() extends LocationAccessViewState {}

final class const LocationAccessReady() extends LocationAccessViewState {}

final class const LocationAccessUnavailable({
  required this.accessState,
  this.message,
}) extends LocationAccessViewState {
  final LocationAccessState accessState;
  final String? message;

  @override
  List<Object?> get props => [accessState, message];
}
