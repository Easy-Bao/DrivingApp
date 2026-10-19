import 'dart:developer' as developer;

/// Use static stage names only; timeline arguments must not contain user data.
Future<T> traceTimelineStage<T>(String name, Future<T> Function() operation) {
  final task = developer.TimelineTask()..start(name);
  try {
    return operation().whenComplete(task.finish);
  } on Object {
    task.finish();
    rethrow;
  }
}
