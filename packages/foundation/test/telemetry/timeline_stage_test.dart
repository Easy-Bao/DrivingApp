import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('returns the operation result', () async {
    expect(await traceTimelineStage('test.stage', () async => 42), 42);
  });

  test('preserves operation failures', () async {
    await expectLater(
      traceTimelineStage<int>(
        'test.stage',
        () async => throw StateError('stage failed'),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
