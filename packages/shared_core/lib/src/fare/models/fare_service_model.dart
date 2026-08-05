import 'package:equatable/equatable.dart';
import 'package:shared_core/src/fare/config/rating_pricing_config.dart';

class FareServiceModel extends Equatable {
  final String id;
  final String serviceName;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final RatingPricingConfig ratingConfig;

  const FareServiceModel({
    required this.id,
    required this.serviceName,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.ratingConfig,
  });

  factory FareServiceModel.fromJson(Map<String, dynamic> json) {
    return FareServiceModel(
      id: _requiredText(json, 'id'),
      serviceName: _requiredText(json, 'serviceName'),
      baseFare: _requiredNumber(json, 'baseFare'),
      perKmRate: _requiredNumber(json, 'perKmRate'),
      perMinuteRate: _requiredNumber(json, 'perMinuteRate'),
      ratingConfig: RatingPricingConfig.fromJson(
        _requiredMap(json, 'ratingPricingConfig'),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'perMinuteRate': perMinuteRate,
      'ratingPricingConfig': ratingConfig.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    serviceName,
    baseFare,
    perKmRate,
    perMinuteRate,
    ratingConfig,
  ];
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing text pricing configuration: $key');
  }
  return value;
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing numeric pricing configuration: $key');
  }
  return value.toDouble();
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw FormatException('Missing pricing configuration object: $key');
  }
  return Map<String, dynamic>.from(value);
}
