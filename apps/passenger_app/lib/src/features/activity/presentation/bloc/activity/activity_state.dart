part of 'activity_bloc.dart';

sealed class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object?> get props => [];
}

final class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

final class ActivityLoading extends ActivityState {
  final int existingRideCount;

  const ActivityLoading({this.existingRideCount = 0});

  bool get hasExistingRides => existingRideCount > 0;

  @override
  List<Object?> get props => [existingRideCount];
}

final class ActivityLoaded extends ActivityState {
  final List<RideHistoryModel> past;
  final List<RideHistoryModel> upcoming;
  final bool hasMore;
  final int? nextOffset;
  final bool isLoadingMore;
  final String? loadMoreError;
  final int weeklyFareCentavos;
  final int weeklyRideCount;

  const ActivityLoaded({
    required this.past,
    required this.upcoming,
    this.hasMore = false,
    this.nextOffset,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.weeklyFareCentavos = 0,
    this.weeklyRideCount = 0,
  });

  List<RideHistoryModel> get rides => [...upcoming, ...past];

  ActivityLoaded copyWith({
    List<RideHistoryModel>? past,
    List<RideHistoryModel>? upcoming,
    bool? hasMore,
    int? nextOffset,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? weeklyFareCentavos,
    int? weeklyRideCount,
  }) {
    return ActivityLoaded(
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

final class ActivityError extends ActivityState {
  final String message;

  const ActivityError({required this.message});

  @override
  List<Object?> get props => [message];
}
