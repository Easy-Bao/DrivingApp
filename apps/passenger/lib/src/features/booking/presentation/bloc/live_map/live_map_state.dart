part of 'live_map_bloc.dart';

sealed class const LiveMapState() extends Equatable {
  @override
  List<Object?> get props => const [];
}

final class const LiveMapInitial() extends LiveMapState;

final class const LiveMapReady(final double currentLat, final double currentLng)
    extends LiveMapState {
  @override
  List<Object?> get props => [currentLat, currentLng];
}
