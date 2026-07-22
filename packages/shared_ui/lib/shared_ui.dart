export 'src/themes/app_themes.dart';
export 'src/transitions/custom_page_transition.dart';
export 'src/utils/safe_route_extra.dart';
export 'src/widgets/custom_toast.dart';
/// SHARED UI SYSTEM & PUBLIC COMPONENTS
///
/// 1. [ENCAPSULATION] Fix the misplaced `transitions/` directory. The folder containing 
///    `driver_transitions.dart` and `passenger_transitions.dart` is sitting directly under `lib/`. 
///    Move it inside `lib/src/transitions/` to keep implementation files private.
///
/// 2. [DOMAIN DECOUPLING] Review `driver_transitions.dart` and `passenger_transitions.dart`. 
///    A generic `shared_ui` package should remain entirely decoupled from business domains. 
///    If these contain feature-specific animations or flows, migrate them out of `shared_ui` 
///    and into their respective feature packages (`driver_services` or `passenger_services`).
///
/// 3. [ARCHITECTURAL ALIGNMENT] Rename or refactor domain-specific transition files to generic, 
///    reusable design tokens (e.g., `slide_up_route_transition.dart`, `fade_scale_transition.dart`) 
///    if they are just visual layout transitions without hardcoded business dependencies.
///
/// 4. [EXPORT MANAGEMENT] Update the main `lib/shared_ui.dart` file. Ensure it cleanly 
///    exports only the public UI design tokens, themes, and generic widgets (like `CustomToast`) 
///    while keeping the underlying layout implementation hidden inside `src/`.
