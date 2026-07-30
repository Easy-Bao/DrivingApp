import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/place_failure.freezed.dart';

@freezed
sealed class PlaceFailure with _$PlaceFailure {
  const factory PlaceFailure.networkError({String? message}) =
      PlaceNetworkError;
  const factory PlaceFailure.serverError({
    required int statusCode,
    String? message,
  }) = PlaceServerError;
  const factory PlaceFailure.parseError({String? message}) = PlaceParseError;
  const factory PlaceFailure.notFound() = PlaceNotFound;
}
