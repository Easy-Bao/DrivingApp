import 'package:equatable/equatable.dart';

sealed class PlaceFailure extends Equatable {
  const PlaceFailure();

  @override
  List<Object?> get props => [];
}

class PlaceNetworkError extends PlaceFailure {
  final String? message;

  const PlaceNetworkError({this.message});

  @override
  List<Object?> get props => [message];
}

class PlaceServerError extends PlaceFailure {
  final int statusCode;
  final String? message;

  const PlaceServerError({required this.statusCode, this.message});

  @override
  List<Object?> get props => [statusCode, message];
}

class PlaceParseError extends PlaceFailure {
  final String? message;

  const PlaceParseError({this.message});

  @override
  List<Object?> get props => [message];
}

class PlaceNotFound extends PlaceFailure {
  const PlaceNotFound();
}

