import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';

class CustomPageTransition({super.settings, super.child}) extends GoTransition {
  this
    : super(
        builder: (route, context, animation, secondaryAnimation, child) {
          final colors = Theme.of(context).colorScheme;
          final primarySlide =
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
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
                end: const Offset(-0.3, 0.0),
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
                      offset: const Offset(-8, 0),
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
