import 'package:equatable/equatable.dart';

class DriverTripHistoryState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int? nextOffset;
  final String? errorMessage;
  final String? loadMoreError;
  final List<Map<String, dynamic>> trips;

  const DriverTripHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextOffset,
    this.errorMessage,
    this.loadMoreError,
    this.trips = const [],
  });

  DriverTripHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
    bool clearNextOffset = false,
    String? errorMessage,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    List<Map<String, dynamic>>? trips,
  }) {
    return DriverTripHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextOffset: clearNextOffset ? null : nextOffset ?? this.nextOffset,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      trips: trips ?? this.trips,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    hasMore,
    nextOffset,
    errorMessage,
    loadMoreError,
    trips,
  ];
}
