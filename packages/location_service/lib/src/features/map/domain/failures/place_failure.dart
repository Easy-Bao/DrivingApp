import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/place_failure.freezed.dart';

@freezed
sealed class PlaceFailure with _$PlaceFailure {
  const factory PlaceFailure.networkError({String? message}) =
      PlaceNetworkFailure;
  const factory PlaceFailure.serverError({
    required int statusCode,
    String? message,
  }) = PlaceServerFailure;
  const factory PlaceFailure.parseError({String? message}) =
      PlaceParseFailure;
  const factory PlaceFailure.notFound() = PlaceNotFoundFailure;
}
