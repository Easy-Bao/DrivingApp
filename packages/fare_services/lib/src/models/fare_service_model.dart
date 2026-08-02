import 'package:equatable/equatable.dart';
import '../config/rating_pricing_config.dart';

/// Server-driven fare service configuration model.
class FareServiceModel extends Equatable {
  final String id;
  final String serviceName;
  final double baseFare;
  final double perKmRate;
  final RatingPricingConfig ratingConfig;

  const FareServiceModel({
    required this.id,
    required this.serviceName,
    required this.baseFare,
    required this.perKmRate,
    required this.ratingConfig,
  });

  factory FareServiceModel.fromJson(Map<String, dynamic> json) {
    return FareServiceModel(
      id: json['id'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
      perKmRate: (json['perKmRate'] as num?)?.toDouble() ?? 0.0,
      ratingConfig: json['ratingPricingConfig'] != null
          ? RatingPricingConfig.fromJson(
              json['ratingPricingConfig'] as Map<String, dynamic>,
            )
          : const RatingPricingConfig(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'ratingPricingConfig': ratingConfig.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    serviceName,
    baseFare,
    perKmRate,
    ratingConfig,
  ];
}
