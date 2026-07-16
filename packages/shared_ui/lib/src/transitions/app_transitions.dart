import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:shared_ui/src/transitions/custom_page_transition.dart';

class AppTransitions {
  AppTransitions._();

  static const push = _CustomPushTransitions();
  static const fade = GoTransitions.fade;
  static const modal = GoTransitions.slide;
  static const none = GoTransitions.none;

  static const Duration pushDuration = Duration(milliseconds: 160);
  static const Duration fadeDuration = Duration(milliseconds: 120);
  static const Duration modalDuration = Duration(milliseconds: 220);

  static void configure() {
    GoTransition.defaultDuration = pushDuration;
    GoTransition.defaultCurve = Curves.easeOutCubic;
  }
}

class _CustomPushTransitions {
  const _CustomPushTransitions();

  GoTransition get toLeft => CustomPageTransition();
}
