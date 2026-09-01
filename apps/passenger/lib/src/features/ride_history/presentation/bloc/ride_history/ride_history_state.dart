part of 'ride_history_bloc.dart';

sealed class const RideHistoryState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const RideHistoryInitial() extends RideHistoryState {}

final class const RideHistoryLoading({this.existingRideCount = 0})
    extends RideHistoryState {
  final int existingRideCount;

  bool get hasExistingRides => existingRideCount > 0;

  @override
  List<Object?> get props => [existingRideCount];
}

final class const RideHistoryLoaded({
  required this.past,
  required this.upcoming,
  this.hasMore = false,
  this.nextOffset,
  this.isLoadingMore = false,
  this.loadMoreError,
  this.weeklyFareCentavos = 0,
  this.weeklyRideCount = 0,
}) extends RideHistoryState {
  final List<RideHistory> past;
  final List<RideHistory> upcoming;
  final bool hasMore;
  final int? nextOffset;
  final bool isLoadingMore;
  final String? loadMoreError;
  final int weeklyFareCentavos;
  final int weeklyRideCount;

  List<RideHistory> get rides => [...upcoming, ...past];

  RideHistoryLoaded copyWith({
    List<RideHistory>? past,
    List<RideHistory>? upcoming,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? weeklyFareCentavos,
    int? weeklyRideCount,
  }) {
    return RideHistoryLoaded(
      past: past ?? this.past,
      upcoming: upcoming ?? this.upcoming,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      weeklyFareCentavos: weeklyFareCentavos ?? this.weeklyFareCentavos,
      weeklyRideCount: weeklyRideCount ?? this.weeklyRideCount,
    );
  }

  @override
  List<Object?> get props => [
    past,
    upcoming,
    hasMore,
    nextOffset,
    isLoadingMore,
    loadMoreError,
    weeklyFareCentavos,
    weeklyRideCount,
  ];
}

final class const RideHistoryError({required this.message})
    extends RideHistoryState {
  final String message;

  @override
  List<Object?> get props => [message];
}
