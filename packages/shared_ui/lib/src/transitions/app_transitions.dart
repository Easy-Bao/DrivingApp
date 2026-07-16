import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:shared_ui/src/transitions/custom_page_transition.dart';

/// Centralized transition manager for GoRouter screens. Sets default page transition
/// durations and routes push navigation requests through a custom platform transition builder.
class AppTransitions {
  AppTransitions._();

  /// Custom push transitions that override default slide animations.
  static const push = _CustomPushTransitions();

  /// Snappy fade transition used for top-level shell routes.
  static const fade = GoTransitions.fade;

  /// Bottom slide-up transition used for action sheets and overlay modal dialogs.
  static const modal = GoTransitions.slide;

  /// Instant transition used when programmatic redirects bypass animations.
  static const none = GoTransitions.none;

  static const Duration pushDuration = Duration(milliseconds: 160);
  static const Duration fadeDuration = Duration(milliseconds: 120);
  static const Duration modalDuration = Duration(milliseconds: 220);

  /// Registers transition overrides with GoTransition properties.
  static void configure() {
    GoTransition.defaultDuration = pushDuration;
    GoTransition.defaultCurve = Curves.easeOutCubic;
  }
}

/// Provides custom slide and parallax transitions for push routes.
class _CustomPushTransitions {
  const _CustomPushTransitions();

  /// Pushed route using native-style slide transition.
  GoTransition get toLeft => CustomPageTransition();
}
