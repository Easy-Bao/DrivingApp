# EasyRide Mobile Applications — UI/UX Audit Implementation Tracker

> **Status:** IN PROGRESS  
> **Constraint:** Passenger Home UI (`apps/passenger/lib/src/features/home/presentation/view/home_page.dart`) remains visually intact per user instruction.

---

## Progress Overview

| Phase / Sprint | Focus Area | Status | Completed Items | Total Items |
|---|---|---|---|---|
| **Sprint 1** | Ergonomic Fixes & Dead Code Removal | 🟢 Completed | 4 | 4 |
| **Sprint 2** | Booking & Active Ride Streamlining | 🟢 Completed | 3 | 3 |
| **Sprint 3** | Shared Design System & Cancellation Dialogs | 🟢 Completed | 2 | 2 |
| **Sprint 4** | Verification, Regression Testing & Static Analysis | 🟢 Completed | 3 | 3 |

---

## Sprint 1: Ergonomic Fixes & Dead Code Removal

- [x] **1.0 Passenger Profile Save Button Ergonomics**
  - **Location:** `apps/passenger/lib/src/features/profile/presentation/view/passenger_profile_page.dart`
  - **Issue:** Save button was placed awkwardly in the top bar.
  - **Action:** Relocated to a clean bottom sticky action bar with safe area padding.
  - **Status:** **DONE** (Committed: `7c671c3b`)

- [x] **1.1 Driver Cash Settlement Auto-Change & Bill Chips**
  - **Location:** `apps/driver/lib/src/features/active_ride/presentation/view/fare_summary_page.dart`
  - **Issue:** Change returned was defaulting to `0.00` and failing validation `received - change == fare` unless manually calculated and typed by driver while driving.
  - **Action:** Auto-compute `change = received - fare` whenever cash received is modified. Add quick denomination bill chips (`Exact`, `₱100`, `₱200`, `₱500`, `₱1,000`).
  - **Status:** **DONE** (Automated change calculation & chips implemented and tested)

- [x] **1.2 Removal of Non-Functional "Coming Soon" Social Login**
  - **Locations:**
    - `apps/driver/lib/src/features/auth/presentation/view/sign_in_page.dart`
    - `apps/passenger/lib/src/features/auth/presentation/view/sign_in_page.dart`
    - `apps/passenger/lib/src/features/auth/presentation/view/sign_up_page.dart`
  - **Issue:** Google Sign-In buttons show a dead toast `"Google Sign-In coming soon"` with no backend OAuth integration.
  - **Action:** Remove placeholder `SocialLoginWidget` buttons until true OAuth is supported.
  - **Status:** **DONE** (Dead buttons removed; layout verified with responsive test passing)

- [x] **1.3 Passenger Forgot Password OTP Verification Bypass Fix**
  - **Location:** `apps/passenger/lib/src/features/auth/presentation/view/verify_otp_page.dart`
  - **Issue:** Forgot password flow bypassed `VerifyOtpSubmitted` event and pushed directly to `resetPasswordConfirm` without validating OTP with backend.
  - **Action:** Submit `VerifyOtpSubmitted` to `VerifyOtpBloc` before navigating to password reset confirmation on success.
  - **Status:** **DONE** (Dispatches `VerifyOtpSubmitted` ensuring backend code verification)

---

## Sprint 2: Core Booking & Active Ride Streamlining

- [x] **2.1 Driver Incoming Request Modal -> Non-blocking Bottom Sheet/Card**
  - **Location:** `apps/driver/lib/src/features/dashboard/presentation/widgets/driver_dashboard/driver_incoming_request_dialog.dart`
  - **Issue:** A fullscreen barrier-dismissible `false` modal dialog traps the driver and obscures the dashboard/map context.
  - **Action:** Aligned to bottom viewport (`Alignment.bottomCenter`) with dismissible semi-transparent barrier, preserving road/map awareness and responsiveness.
  - **Status:** **DONE** (Updated alignment and barrier; all 6 widget tests passing)

- [x] **2.2 Passenger `DriverMatchedPage` Transition Delay Streamlining**
  - **Location:** `apps/passenger/lib/src/features/active_ride/presentation/view/driver_matched_page.dart`
  - **Issue:** Intermediate screen with an artificial 1-second `Timer` before pushing `trackDriver`, causing jarring navigation hops.
  - **Action:** Increased countdown to 4s with visible indicator, immediate "Track Your Driver" button, and auto-pause when driver details sheet is inspected.
  - **Status:** **DONE** (Implemented countdown with pause support; widget tests passing)

- [x] **2.3 Ride Cancellation Confirmation & Flow Polish**
  - **Locations:**
    - `apps/passenger/lib/src/features/active_ride/presentation/widgets/trip_cancellation_dialog.dart`
    - `apps/driver/lib/src/features/active_ride/presentation/widgets/driver_ride_cancellation_sheet.dart`
  - **Action:** Standardized destructive button styling with `FilledButton` and error theme tokens across passenger and driver.
  - **Status:** **DONE** (Verified and passing widget tests)

---

## Sprint 3: Shared Design System & Consistency

- [x] **3.1 Cohesive Cancellation Bottom Sheets**
  - **Locations:** `apps/passenger` & `apps/driver` cancellation dialogs
  - **Action:** Standardized design tokens, spacing, and reason selectors using `design_system` components.
  - **Status:** **DONE**

- [x] **3.2 Deprecate or Prune Unused UI Placeholders**
  - **Locations:** Driver & Passenger dead widget imports
  - **Action:** Cleaned up unused imports, removed dead placeholders from screens.
  - **Status:** **DONE**

---

## Sprint 4: Verification, Regression Testing & Static Analysis

- [x] **4.1 Driver Test Suite Verification**
  - Run all driver tests (`flutter test` in `apps/driver`) — 174 of 174 tests passing (100%).
  - **Status:** **DONE**

- [x] **4.2 Passenger Test Suite Verification**
  - Run all passenger tests (`flutter test` in `apps/passenger`) — 315 of 315 tests passing (100%).
  - **Status:** **DONE**

- [x] **4.3 Monorepo Static Analysis**
  - Run `flutter analyze` across `apps/driver`, `apps/passenger`, and `packages/design_system` — 0 errors, 0 warnings.
  - **Status:** **DONE**

---

## Explicit Product Constraints Preserved

1. **Passenger Home Screen (`HomePage`):**
   - The UI layout, cards, map, search bar, and home actions are strictly preserved with NO visual changes, respecting explicit user constraint: *"Proceed all proposed except for changes UI on home for passenger"*.
2. **Backend & Cash Settlement Authority:**
   - Go backend remains the single source of truth for all cash settlement transactions. No fake client mock gateways are introduced.
3. **Environment & Unrelated Work:**
   - Uncommitted backend and foundation configuration files are preserved untouched.
