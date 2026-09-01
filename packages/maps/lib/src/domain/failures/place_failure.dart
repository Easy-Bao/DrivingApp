import 'package:foundation/foundation.dart';

class const PlaceFailure([
  super.message = 'An error occurred with place service.',
]) extends Failure {}

class const PlaceNetworkError({String? message}) extends PlaceFailure {
  this : super(message ?? 'Network error occurred in place service.');
}

class const PlaceParseError({String? message}) extends PlaceFailure {
  this : super(message ?? 'Parsing error occurred in place service.');
}
