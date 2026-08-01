import 'package:flutter/material.dart';
import 'package:go_transitions/go_transitions.dart';

class CustomPageTransition extends GoTransition {
  CustomPageTransition({
    super.settings,
    super.child,
  }) : super(
          builder: (route, context, animation, secondaryAnimation, child) {
            final primarySlide = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            );
            final secondarySlide = Tween<Offset>(
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
                        color: Colors.black.withValues(alpha: 0.08),
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
