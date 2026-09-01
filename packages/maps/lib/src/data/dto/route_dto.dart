import 'package:maps/src/domain/entities/route.dart';

class const RouteDto(this.route) {
  final Route route;

  factory fromJson(Map<String, dynamic> json) {
    return RouteDto(Route.fromJson(json));
  }

  Route toDomain() => route;

  Map<String, dynamic> toJson() => route.toJson();
}
