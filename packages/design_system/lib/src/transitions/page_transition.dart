import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';

class CustomPageTransition({this.fromRight = true, super.settings, super.child})
    extends GoTransition {
  final bool fromRight;

  this
    : super(
        builder: (route, context, animation, secondaryAnimation, child) {
          final horizontalDirection = fromRight ? 1.0 : -1.0;
          final colors = Theme.of(context).colorScheme;
          final primarySlide =
              Tween<Offset>(
                begin: Offset(horizontalDirection, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
          final secondarySlide =
              Tween<Offset>(
                begin: Offset.zero,
                end: Offset(-0.3 * horizontalDirection, 0.0),
              ).animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
          return SlideTransition(
            position: secondarySlide,
            child: SlideTransition(
              position: primarySlide,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: Offset(-8 * horizontalDirection, 0.0),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
      );
}
