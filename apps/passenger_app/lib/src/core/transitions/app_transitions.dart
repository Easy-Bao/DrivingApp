import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

/**
 * Centralized screen-transition registry for the passenger application.
 *
 * Route transitions across the app previously defaulted to GoTransition's
 * 300ms linear curve, which reads as sluggish on modern hardware. This class
 * establishes a single authoritative configuration that is applied once at
 * app bootstrap via [configure], eliminating per-route timing duplication
 * and ensuring a cohesive, premium navigation feel throughout all screens.
 *
 * Transition taxonomy:
 * - [push]  Standard content pushes (search, detail screens).
 * - [fade]  Shell-tab switches and overlapping views where position is irrelevant.
 * - [modal] Full-screen action sheets and form overlays (slide up from bottom).
 * - [none]  Programmatic route replacements that should appear instant.
 *
 * Usage: call [AppTransitions.configure] before [runApp] in main.dart.
 */
class AppTransitions {
  AppTransitions._();

  /**
   * 160ms easeOutCubic: the universal push transition for content navigation.
   * Short enough to feel instant on a fast device; long enough to register as
   * intentional movement rather than a jarring cut.
   */
  static const push = GoTransitions.slide;

  /**
   * 120ms easeOut fade: used for shell-level tab switches where spatial
   * direction would be misleading (tabs do not have a linear left/right order).
   */
  static const fade = GoTransitions.fade;

  /**
   * 220ms easeOutCubic slide-up: used for form overlays or modal flows that
   * originate conceptually "from below" (e.g. add-category, map-pin picker).
   * Slightly longer than push to communicate a change in modal depth.
   */
  static const modal = GoTransitions.slide;

  /**
   * Zero-duration invisible transition: used when the router replaces a route
   * programmatically and any animation would look incorrect (e.g. auth redirect).
   */
  static const none = GoTransitions.none;

  /** Duration constants that route declarations import directly. */
  static const Duration pushDuration = Duration(milliseconds: 160);
  static const Duration fadeDuration = Duration(milliseconds: 120);
  static const Duration modalDuration = Duration(milliseconds: 220);

  /**
   * Must be called once before [runApp]. Sets the global GoTransition defaults
   * so that any ChildRoute that does not specify its own transition implicitly
   * inherits the snappy easeOutCubic curve and 160ms timing defined here.
   */
  static void configure() {
    GoTransition.defaultDuration = pushDuration;
    GoTransition.defaultCurve = Curves.easeOutCubic;
  }
}
