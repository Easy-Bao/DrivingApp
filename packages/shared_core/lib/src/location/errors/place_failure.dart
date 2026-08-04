import 'package:shared_core/shared_core.dart';

class PlaceFailure extends Failure {
  const PlaceFailure([super.message = 'An error occurred with place service.']);
}

class PlaceNetworkError extends PlaceFailure {
  const PlaceNetworkError({String? message})
    : super(message ?? 'Network error occurred in place service.');
}

class PlaceParseError extends PlaceFailure {
  const PlaceParseError({String? message})
    : super(message ?? 'Parsing error occurred in place service.');
}
