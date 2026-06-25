import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/place_model.freezed.dart';
part 'generated/place_model.g.dart';

/**
 * PlaceModel represents a geocoded address or location suggestion.
 */
@freezed
abstract class PlaceModel with _$PlaceModel {
  const factory PlaceModel({
    required String id,
    required String name,
    required String fullAddress,
    required double latitude,
    required double longitude,
    String? category,
    double? distanceKm,
  }) = _PlaceModel;

  factory PlaceModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceModelFromJson(json);
}
