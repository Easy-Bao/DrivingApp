import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// A custom page transitions builder that replicates native platform navigation.
///
/// It provides a smooth right-to-left slide animation on push, a left-to-right
/// slide on pop, and a subtle parallax shift to the left for the underlying screen
/// when another screen is pushed on top of it.
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

            // Add a subtle screen shadow under the entering route to enhance the depth
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
