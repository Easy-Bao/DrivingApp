import 'package:maps/src/domain/entities/route.dart';

class RouteDto {
  final Route route;

  const RouteDto(this.route);

  factory RouteDto.fromJson(Map<String, dynamic> json) {
    return RouteDto(Route.fromJson(json));
  }

  Route toDomain() => route;

  Map<String, dynamic> toJson() => route.toJson();
}
