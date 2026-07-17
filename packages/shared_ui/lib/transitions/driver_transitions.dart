import 'package:go_transitions/go_transitions.dart';

class AppTransitions {
  AppTransitions._();

  static const push = _NoTransition();
  static const fade = GoTransitions.none;
  static const modal = _NoTransition();
  static const none = GoTransitions.none;

  static const Duration pushDuration = Duration.zero;
  static const Duration fadeDuration = Duration.zero;
  static const Duration modalDuration = Duration.zero;
}

class _NoTransition {
  const _NoTransition();

  dynamic get toLeft => GoTransitions.none;
  dynamic get toRight => GoTransitions.none;
  dynamic get toTop => GoTransitions.none;
  dynamic get toBottom => GoTransitions.none;
}
