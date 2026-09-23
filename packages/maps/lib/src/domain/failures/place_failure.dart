import 'package:foundation/foundation.dart';

sealed class const PlaceFailure([
  super.message = 'An error occurred with place service.',
]) extends Failure {}

final class const PlaceNetworkError({String? message}) extends PlaceFailure {
  this : super(message ?? 'Network error occurred in place service.');
}

final class const PlaceParseError({String? message}) extends PlaceFailure {
  this : super(message ?? 'Parsing error occurred in place service.');
}
