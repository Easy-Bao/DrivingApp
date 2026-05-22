import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_model.freezed.dart';
part 'route_model.g.dart';

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

extension RouteModelExtension on RouteModel {
  Duration get estimatedTime => Duration(seconds: durationSeconds);
}

// For backwards compatibility:
class RouteModelLegacyAdapter {
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
