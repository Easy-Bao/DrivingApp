import 'package:driver_app/src/core/location/location.dart';
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
    this.isPromptSuppressed = false,
    this.message,
  });

  final LocationAccessState accessState;
  final bool isPromptSuppressed;
  final String? message;

  DriverLocationAccessUnavailable copyWith({
    bool? isPromptSuppressed,
    String? message,
  }) {
    return DriverLocationAccessUnavailable(
      accessState: accessState,
      isPromptSuppressed: isPromptSuppressed ?? this.isPromptSuppressed,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [accessState, isPromptSuppressed, message];
}
