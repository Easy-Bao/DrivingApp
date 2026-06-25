import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/route_model.freezed.dart';
part 'generated/route_model.g.dart';

/**
 * RouteModel represents route coordinates, metrics, and description.
 */
@freezed
abstract class RouteModel with _$RouteModel {
  const factory RouteModel({
    required List<List<double>> polylinePoints,
    required double distanceKm,
    required int durationSeconds,
    @Default('') String summary,
  }) = _RouteModel;

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      _$RouteModelFromJson(json);
}

/**
 * Extension on RouteModel to convert durationSeconds to a Duration object.
 */
extension RouteModelExtension on RouteModel {
  Duration get estimatedTime => Duration(seconds: durationSeconds);
}

/**
 * Legacy Adapter for RouteModel to construct with Duration instead of int seconds.
 */
class RouteModelLegacyAdapter {
  RouteModelLegacyAdapter._();

  static RouteModel create({
    required List<List<double>> polylinePoints,
    required double distanceKm,
    required Duration estimatedTime,
    String summary = '',
  }) {
    return RouteModel(
      polylinePoints: polylinePoints,
      distanceKm: distanceKm,
      durationSeconds: estimatedTime.inSeconds,
      summary: summary,
    );
  }
}
