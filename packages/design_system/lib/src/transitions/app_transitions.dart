import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:design_system/src/transitions/custom_page_transition.dart';

class AppTransitions._() {
  static const push = _CustomPushTransitions();
  static const fade = GoTransitions.fade;
  static const modal = GoTransitions.slide;
  static const none = GoTransitions.none;

  static final sharedAxisHorizontal = _SharedAxisPageTransition(
    transitionType: SharedAxisTransitionType.horizontal,
  );

  static final fadeThrough = _FadeThroughPageTransition();

  static const Duration pushDuration = Duration(milliseconds: 300);
  static const Duration fadeDuration = Duration(milliseconds: 300);
  static const Duration modalDuration = Duration(milliseconds: 300);

  static void configure() {
    GoTransition.defaultDuration = pushDuration;
    GoTransition.defaultCurve = Curves.easeOutCubic;
  }
}

class _SharedAxisPageTransition({
  required SharedAxisTransitionType transitionType,
}) extends GoTransition {
  this
    : super(
        builder: (route, context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          );
        },
      );
}

class _FadeThroughPageTransition() extends GoTransition {
  this
    : super(
        builder: (route, context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            child: child,
          );
        },
      );
}

class const _CustomPushTransitions() {
  GoTransition get toLeft => CustomPageTransition();
  GoTransition get toRight => CustomPageTransition();
  GoTransition get toTop => GoTransitions.slide;
  GoTransition get toBottom => GoTransitions.slide;
}
