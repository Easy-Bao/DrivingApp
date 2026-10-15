import 'dart:math';

final _requestIdRandom = Random.secure();

String newRequestCorrelationId() => List<int>.generate(
  16,
  (_) => _requestIdRandom.nextInt(256),
).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
