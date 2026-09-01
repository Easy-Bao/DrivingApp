import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';

enum PublicDriverSummaryStatus { initial, loading, success, failure }

class const PublicDriverSummaryState({
  this.status = PublicDriverSummaryStatus.initial,
  this.summaries = const [],
  this.errorMessage,
}) extends Equatable {
  final PublicDriverSummaryStatus status;
  final List<PublicDriverSummary> summaries;
  final String? errorMessage;

  PublicDriverSummaryState copyWith({
    PublicDriverSummaryStatus? status,
    List<PublicDriverSummary>? summaries,
    String? errorMessage,
  }) {
    return PublicDriverSummaryState(
      status: status ?? this.status,
      summaries: summaries ?? this.summaries,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == PublicDriverSummaryStatus.loading;

  @override
  List<Object?> get props => [status, summaries, errorMessage];
}
