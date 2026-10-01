import 'package:passenger/src/app/passenger_bootstrap.dart';

Future<void> main() => bootstrapPassengerApp();
/*
///TODO:
/// Perform a full deployment-readiness audit across BOTH Passenger App and Driver App.
/// Do not only fix the exact screens/issues listed below. Trace the same patterns across
/// shared packages, networking, authentication, navigation, forms, loading states,
/// animations, local persistence, and release configuration.
///
/// Check for small related issues as well, especially anything that could behave
/// differently between:
/// - Flutter debug build
/// - Flutter profile build
/// - Flutter release APK
/// - Android emulator
/// - Physical Android device through USB debugging
/// - Physical Android device through local Wi-Fi/LAN
///
/// The goal is to make both applications stable and deployment-ready, not just patch
/// isolated symptoms.


///TODO:
/// Verify that release builds behave correctly and do not depend on debug-only behavior.
///
/// Test the actual generated release APK on a physical Android device.
///
/// Review:
/// - API base URL
/// - .env usage
/// - compile-time environment variables
/// - Mapbox token/configuration
/// - Android permissions
/// - network security configuration
/// - secure storage
/// - SharedPreferences
/// - authentication session restoration
/// - release optimization / R8 / ProGuard behavior
/// - location permission handling
/// - background/foreground lifecycle behavior
///
/// The release APK should behave consistently with debug builds unless a difference
/// is intentional.


///BUG:
/// Navigating from Passenger Home -> Add Place and then returning can show a delayed
/// or chunky transition.
///
/// There may be a visible pause before the back-navigation animation begins or
/// finishes.
///
/// Other animations may contain similar jank.
///
///FIX:
/// Profile navigation and animation performance across both apps.
///
/// Specifically inspect:
/// - Home -> Add Place
/// - Add Place -> Home
/// - destination selection
/// - saved place selection
/// - ride details
/// - tracking
/// - driver offers
/// - profile
/// - authentication
/// - modal/bottom sheet transitions
///
/// Check for expensive work occurring during navigation such as:
/// - synchronous SharedPreferences reads/writes
/// - unnecessary repository calls
/// - state restoration
/// - heavy widget rebuilds
/// - large map rebuilds
/// - image decoding
/// - JSON processing
/// - unnecessary Bloc/Cubit emissions
/// - navigation waiting for persistence
///
/// Navigation animation should not wait for non-critical async work.
///
/// Save/persist state independently when possible instead of blocking route pop.
///
/// Check for duplicate:
/// - AnimationController
/// - AnimatedSwitcher
/// - AnimatedContainer
/// - Hero
/// - route animation
/// - custom fade/slide animations
///
/// Avoid multiple animations fighting over the same widget.


///TODO:
/// Perform a complete animation audit across Passenger App and Driver App.
///
/// Check for:
/// - chunky animation
/// - delayed animation
/// - duplicate animation
/// - unnecessary animation
/// - inconsistent duration
/// - inconsistent animation curves
/// - animation running during heavy rebuilds
/// - map-related frame drops
/// - unnecessary Hero widgets
///
/// Prefer simple and consistent transitions.
///
/// Animation should support usability and should not exist only because the widget
/// allows animation.


///TODO:
/// Audit navigation architecture across both applications.
///
/// Check:
/// - duplicate route pushes
/// - navigation triggered more than once
/// - stale BuildContext usage
/// - navigation after disposed widgets
/// - async gaps before Navigator/router calls
/// - unnecessary redirect loops
/// - route restoration
/// - back-button behavior
/// - pop result handling
/// - animation consistency
///
/// Navigation should remain predictable after app rebuild, hot restart, process
/// restoration, and session restoration.


///TODO:
/// Audit all layouts on multiple Android screen sizes.
///
/// Test:
/// - small phones
/// - normal phones
/// - tall screens
/// - devices with gesture navigation
/// - devices with three-button navigation
/// - different text scaling
/// - keyboard visible/hidden
///
/// Check for:
/// - RenderFlex overflow
/// - clipped content
/// - incorrect SafeArea handling
/// - hardcoded heights
/// - hardcoded widths
/// - excessive Spacer usage
/// - overflowing dialogs
/// - bottom-sheet keyboard overlap
/// - buttons hidden behind keyboard/system navigation.
///
/// Prefer responsive constraints instead of device-specific magic values.


///TODO:
/// Audit loading-state behavior across both applications.
///
/// Every async screen should intentionally distinguish between:
///
/// Initial
/// Loading
/// Success
/// Empty
/// Failure
/// Refreshing
///
/// where applicable.
///
/// Avoid treating every rebuild as Loading.
///
/// Preserve existing data during refresh when possible.
///
/// Example:
/// Existing data + refresh request
///
/// should generally continue displaying existing data with a subtle refresh indicator
/// instead of replacing the entire screen with a skeleton again.


///TODO:
/// Check unnecessary rebuilds throughout Passenger and Driver.
///
/// Review:
/// - BlocBuilder
/// - BlocConsumer
/// - BlocSelector
/// - context.watch
/// - context.select
/// - AnimatedBuilder
/// - ValueListenableBuilder
///
/// Large screens should not rebuild because an unrelated small state value changed.
///
/// Maps in particular should not rebuild unnecessarily.


///TODO:
/// Audit async lifecycle safety.
///
/// Search for async operations that update state after a widget/cubit/bloc has already
/// been disposed or closed.
///
/// Check:
/// - mounted
/// - context.mounted
/// - Bloc/Cubit isClosed
/// - cancellation
/// - timers
/// - streams
/// - subscriptions
/// - location listeners
/// - map listeners
/// - debounce/throttle implementations.
///
/// Prevent lifecycle-related crashes that may only appear on physical devices or
/// release builds.


///TODO:
/// Review Passenger and Driver app lifecycle behavior.
///
/// Test:
/// - app starts
/// - app goes background
/// - app returns foreground
/// - screen locks
/// - network temporarily disconnects
/// - Wi-Fi changes to mobile data
/// - mobile data changes to Wi-Fi
/// - backend temporarily becomes unreachable
/// - application remains idle for a long period
///
/// Ensure:
/// - session remains valid when appropriate
/// - driver online state behaves intentionally
/// - tracking resumes correctly
/// - stale network connections recover
/// - subscriptions do not duplicate
/// - requests are not sent twice
/// - ride state remains consistent.


///TODO:
/// Review session/authentication restoration for Passenger and Driver.
///
/// Verify app rebuild/restart does not incorrectly invalidate valid sessions.
///
/// Check:
/// - access token restoration
/// - refresh token behavior
/// - secure storage
/// - logout cleanup
/// - expired token handling
/// - concurrent token refresh
/// - app startup race conditions
/// - session state synchronization.
///
/// Avoid forcing users to log in again because an unrelated application state changed.


///TODO:
/// Review all error messages and validation messages.
///
/// Ensure errors are:
/// - understandable
/// - specific enough to be useful
/// - consistent between Passenger and Driver
/// - mapped from the correct failure type
/// - not leaking internal/server-sensitive details.
///
/// Avoid using:
///
/// "Something went wrong. Try again."
///
/// as the response for every possible failure.
///
/// Keep it only as a final fallback for genuinely unknown failures.


///TODO:
/// Review duplicate code between Passenger App, Driver App, and shared packages.
///
/// Shared behaviors such as:
/// - networking
/// - errors
/// - authentication primitives
/// - text fields
/// - loading indicators
/// - common dialogs
/// - navigation utilities
/// - validation
/// - design tokens
///
/// should not have slightly different implementations unless the apps genuinely require
/// different behavior.
///
/// Do not over-abstract. Extract only behavior that is truly shared.


///TODO:
/// Perform final deployment-readiness testing.
///
/// Test Passenger and Driver separately using:
///
/// 1. Flutter debug build on emulator.
/// 2. Flutter debug build on physical Android device.
/// 3. Physical Android device using USB debugging.
/// 4. Physical Android device using local Wi-Fi/LAN backend connection.
/// 5. Flutter profile build.
/// 6. Flutter release APK installed manually.
///
/// Verify at minimum:
/// - Registration
/// - Sign In
/// - Sign Out
/// - Session restoration
/// - Password reset
/// - Destination search
/// - Saved places
/// - Nearby drivers
/// - Driver offers
/// - Ride creation
/// - Ride acceptance
/// - Ride tracking
/// - Cancellation
/// - Completion
/// - Ratings
/// - Chat
/// - Driver online/offline
/// - Driver location telemetry
/// - Driver trip lifecycle
/// - Earnings/history
/// - Profile
/// - network disconnect/reconnect
/// - keyboard behavior
/// - navigation
/// - loading states
/// - release API connectivity.


///FIX:
/// Do not consider this task complete after only fixing the visible symptoms.
///
/// Trace each issue to its root cause.
///
/// If the same implementation pattern exists elsewhere, fix those locations as part of
/// the same pass.
///
/// Keep the architecture clean and consistent with the existing project structure.
///
/// Avoid:
/// - unnecessary abstractions
/// - temporary hacks
/// - broad ignore rules
/// - deprecated APIs
/// - duplicated fixes
/// - hardcoded device-specific values
/// - debug-only solutions that break release builds.
///
/// Final result should make BOTH Passenger App and Driver App more stable for real-device
/// testing and deployment.
*/
