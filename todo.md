1. Passenger Tab the help should replace with saved placed also the layout formation is home, activity, center fab, saved place, account. Remove the add saved place on dashboard instead migrate it everything to saved place screen also the UI is different yet easy to navigate.
2. The activity screen get return status code 404.
3. Passenger account info didn't fetch just leave blank strictly avoid hardcoded fallback it will not determine if the data fetched or not.
4. When i book ride i get directed instantly to driver profile like that Book test driver directly even there's no online driver so when i book it will stock too map.
5. Removed the center fab action and it's all implementation so the final is Home, Activity, Saved Placed, Profile. So the layout is similar to this 
┌────────────────────────────────────────┐
│  EasyRide                    [Bell_Icon]│ <── Header
│  Ready to ride today?                  │
│  📍 Zamboanga City                     │ <── Simplified local city/area
├────────────────────────────────────────┤
│  🔍 Enter destination                  │ <── Prominent, primary action bar
├────────────────────────────────────────┤
│  Quick Shortcuts                       │
│  ┌──────────────────┐┌────────────────┐│
│  │ 🏠 Home          ││ 💼 Work        ││ <── Set once, tap to instantly book
│  │ (Tap to set)     ││ (Tap to set)   ││
│  └──────────────────┘└────────────────┘│
├────────────────────────────────────────┤
│                                        │
│                                        │
│          ✨ Where to?                  │ <── Clean, modern empty state
│     Your recent trips will appear      │     (Replaces the blank white void
│         here once you ride!            │      without using fake mock data)
│                                        │
│                                        │
├────────────────────────────────────────┤
│ [Home]    [Activity]    [Inbox] [Account] <── Balanced 4-tab bar (No center "+")
└────────────────────────────────────────┘
No quickshortcut
but can be enhance or changes that suitable for the layout and professional and follow UI/UX.
6. The folder structure is mess the home/ folder is merged with booking screen flow, strictly only that inside the dashboard/homescreen like view all, search destinitation. So the final is 
src/
auth/
presentation/screens, presenation/widgets, auto_module, auth_routes
blocs/
profile/
home/
trip/
book/
saved_placed/
activity/
shared/

this is under src also i dont think there's a shared because this is indenpendent ui and no custom touastification yet.

7. On 6 should be follow how the passenger app structure and apply to driver app should like Featured First Architecture like this
Here is how your passenger_app (or driver_app) internal structure should look under Clean Architecture, mapping cleanly to your external packages.

The Model Migration Dilemma
Rule of Thumb: Core/Global models that are reused across multiple features (e.g., User, Location, Trip) should live in your external packages (core_models, location_service). Feature-specific models that nobody else cares about (e.g., BiddingSession, ChatPayload) should stay inside their respective feature’s data/domain layers.

Clean Architecture Directory Structure
Plaintext
as for DI let go_router_modular handle it no need to create di/ on core/as well for routing 
apps/passenger_app/lib/
├── main.dart                  # App initialization, Firebase/Env configuration
├── core/                      # App-scoped configurations & integrations
│   ├── di/                    # GetIt service locator setup
│   │   └── injection.dart
│   ├── network/               # App-specific HTTP/WebSocket wrapper configurations
│   │   ├── api_client.dart
│   │   └── socket_client.dart
│   ├── routing/               # GoRouter / AutoRoute path definitions
│   │   └── app_router.dart
│   └── theme/                 # App-specific overrides of shared_ui themes
│       └── app_theme.dart
│
├── features/                  # Highly modular feature folders
│   ├── auth/
│   │   ├── data/              # Consumes session_service package
│   │   │   ├── datasources/   # Local/Remote auth data providers
│   │   │   ├── models/        # Auth tokens, local session mappings
│   │   │   └── repositories/  # Auth repo implementations
│   │   ├── domain/
│   │   │   ├── entities/      # App-specific Auth state definitions
│   │   │   ├── repositories/  # Contract interfaces for Auth
│   │   │   └── usecases/      # LoginWithOTP, Logout, VerifySession
│   │   └── presentation/
│   │       ├── bloc/          # AuthBloc, AuthState, AuthEvent
│   │       ├── screens/       # LoginScreen, OtpScreen
│   │       └── widgets/       # Localized otp_timer_field, phone_input
│   │
│   ├── booking/               # Core booking flow (Consumes location_service & passenger_services)
│   │   ├── data/
│   │   │   ├── datasources/   # WebSocket event streams for matching, Bidding API HTTP calls
│   │   │   ├── models/        # BidRequestModel, FareBreakdownModel
│   │   │   └── repositories/  # BookingRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/      # Note: Reuses shared 'Trip'/'Location' entities from core_models package
│   │   │   ├── repositories/  # BookingRepository interface
│   │   │   └── usecases/      # CreateBidSession, AcceptCounterOffer, CancelBooking
│   │   └── presentation/
│   │       ├── bloc/          # BookingBloc, MatchingCubit, MapOverlayCubit
│   │       ├── screens/       # HomeScreen, ActiveTripScreen, ReceiptScreen
│   │       └── widgets/       # DestinationSelector, DriverOfferCard, FareSlider
│   │
│   ├── chat/                  # Passenger-Driver interactions (Consumes backend chat-service)
│   │   ├── data/
│   │   │   ├── datasources/   # Chat history HTTP endpoints, real-time message socket listeners
│   │   │   ├── models/        # MessageModel, ChatRoomModel
│   │   │   └── repositories/  # ChatRepositoryImpl
│   │   ├── domain/
│   │   │   ├── entities/      # TextMessage, PresetQuickReply
│   │   │   ├── repositories/  # ChatRepository interface
│   │   │   └── usecases/      # SendMessage, StreamMessages, MarkAsRead
│   │   └── presentation/
│   │       ├── bloc/          # ChatBloc, QuickReplyCubit
│   │       ├── screens/       # LiveChatRoomScreen
│   │       └── widgets/       # ChatBubble, MessageInputField
│   │
│   ├── saved_places/          # Favorite locations list
│   │   ├── data/
│   │   │   ├── datasources/   # local database (Isar/Hive) or remote sync endpoints
│   │   │   ├── models/        # SavedAddressModel
│   │   │   └── repositories/  # SavedPlacesRepositoryImpl
│   │   ├── domain/
│   │   │   ├── repositories/  # SavedPlacesRepository interface
│   │   │   └── usecases/      # GetSavedPlaces, AddFavoritePlace, DeleteFavoritePlace
│   │   └── presentation/
│   │       ├── bloc/          # SavedPlacesBloc
│   │       ├── screens/       # FavoritesManagementScreen
│   │       └── widgets/       # HomeAddressTile, WorkAddressTile
│   │
│   └── activity/              # Past trip history
│       ├── data/
│       │   ├── models/        # HistoricTripSummaryModel
│       │   └── repositories/  # ActivityRepositoryImpl
│       ├── domain/
│       │   └── usecases/      # FetchTripHistory, DownloadReceiptPdf
│       └── presentation/
│           ├── bloc/          # ActivityHistoryBloc
│           ├── screens/       # TripHistoryScreen
│           └── widgets/       # PastTripRowItem, ReceiptBottomSheet
│
└── shared/                    # App-specific internal utilities (Not scalable enough for shared_ui)
    ├── utils/                 # Extension methods, DateFormatters
    └── widgets/               # PassengerApp-specific layout wrappers (e.g., CustomPassengerScaffold)
Guidelines for Managing Models Between Packages vs. Features

For this question give suggestion.

1. What Stays Inside the External core_models Package?
Models representing fundamental system components that cross boundary lines between passenger, driver, and backend frameworks.

User / DriverProfile / PassengerProfile: Needed across both apps and authentication routines.

Location / Coordinate: Used everywhere from UI mapping to telemetry, search logic, and fare pipelines.

Trip / TripStatus: The definitive state machine definition shared by all parts of the app ecosystem.

2. What Belongs inside a Feature's Local data/models/ Directory?
Models serving as strict contracts for unique API responses or data layers that do not influence other components.

BidRequestModel / CounterOfferModel: Exclusively handled inside the booking module matching phase.

MessageModel: Data schemas mapped straight from WebSockets that only the chat feature consumes.

SavedAddressModel: Specific schema layout matching your local database engine configuration for storage properties.

This changes should apply both driver and passenger.



Suggestion 
It’s easy to look at both and think, "Aren't these doing the exact same thing?"While they both deal with favorite addresses, they serve two completely different stages of the passenger’s user experience: instant action versus address management.Here is how they divide and conquer to make your booking flow seamless:1. Quick Shortcuts (Dashboard) = Instant 1-Tap BookingThe shortcuts on your Home screen are there for extreme speed. When a user opens your app, they are usually in a hurry (e.g., leaving the house for work or heading home from a busy market).How it works: Tapping "Home" or "Work" directly on the dashboard bypasses the search screen completely. It immediately sets the coordinates and takes the user straight to the "Select Driver / Confirm Booking" screen.The limit: To keep the dashboard clean, you only show the absolute top two destinations (Home and Work).2. Saved Places (Tab Bar) = The Management HubThe Saved Places tab is where the user goes when they have time to organize their profile, or when they want to book a trip to a location that isn't just "Home" or "Work."How it works: This is a dedicated screen where users can:Add, edit, or delete addresses.Manage a larger list of favorite places that don't fit on the main dashboard (e.g., 🏫 School, 🏋️ Gym, 🛒 KCC Mall, 🏥 City Hospital).Set up or change what "Home" and "Work" actually point to.The flow: If a user taps "Home" on the dashboard but hasn't set it yet, your app can deep-link them directly to this Saved Places tab to configure it.Summary of RolesFeatureWhere it livesMax CapacityPrimary PurposeQuick ShortcutsHome Screen2 (Home / Work)Frictionless speed. 1-tap and you are booking a driver right now.Saved PlacesBottom TabUnlimitedOrganization & variety. Managing all addresses and booking less-frequent favorites. Max capacity to fit the quick action is 5 with horizontal scrollable.



Here is the complete rewrite and optimization plan for your todo.md, capturing all your structural corrections, UI layouts, feature behavior policies, and the Clean Feature-First Architecture layout for both apps using go_router_modular (without explicit di/ or routing/ core directories).

TODO.md
1. Directory Restructuring & Architecture Alignment
Enforce Strict Clean Feature-First Layout: Migrate both passenger_app and driver_app away from nested or messy view structures to the flat, scalable architecture below under src/.

Remove Core di/ and routing/ folders: Let go_router_modular handle dependency injection and route registrations directly inside the app/feature module files.

Remove Global Internal shared/: Rely on external packages (shared_ui, core_models, etc.) for true sharing; internal feature-specific variations live locally within their feature folder.

Updated Blueprint for passenger_app & driver_app
Plaintext
apps/[passenger_app OR driver_app]/lib/
├── main.dart                  # App initialization, Firebase/Env configuration
├── app_module.dart            # Root Modular configuration (Handles top-level DI & routes)
├── app_widget.dart            # Initialization of MaterialApp.router
└── src/
    ├── core/                  # App-scoped configurations & integrations
    │   └── network/           # App-specific HTTP/WebSocket configurations
    │       ├── api_client.dart
    │       └── socket_client.dart
    │
    └── features/              # Highly modular, flat feature directories
        ├── auth/
        │   ├── data/          # Consumes session_service package
        │   │   ├── datasources/
        │   │   ├── models/    # Auth tokens, local session mappings
        │   │   └── repositories/
        │   ├── domain/
        │   │   ├── entities/
        │   │   └── repositories/
        │   └── presentation/
        │       ├── bloc/      # AuthBloc, AuthState, AuthEvent
        │       ├── screens/   # LoginScreen, OtpScreen
        │       └── widgets/   # Localized otp_timer_field, phone_input
        │
        ├── home/              # Strict Dashboard focus only (No booking flow mixed here)
        │   ├── presentation/
        │   │   ├── bloc/      # HomeCubit/Bloc
        │   │   ├── screens/   # HomeScreen (View all, Search destination triggers)
        │   │   └── widgets/   # DestinationSelectorBar, ShortcutCard
        │
        ├── booking/           # Consolidated core booking flow
        │   ├── data/
        │   │   ├── datasources/ # WebSocket event streams for matching, Bidding API HTTP calls
        │   │   ├── models/    # BidRequestModel, CounterOfferModel
        │   │   └── repositories/
        │   ├── domain/
        │   │   ├── entities/  # Reuses shared 'Trip'/'Location' from core_models package
        │   │   └── repositories/
        │   └── presentation/
        │       ├── bloc/      # BookingBloc, MatchingCubit, MapOverlayCubit
        │       ├── screens/   # ActiveTripScreen, ReceiptScreen, DriverProfileScreen
        │       └── widgets/   # DriverOfferCard, FareSlider
        │
        ├── chat/              # Passenger-Driver interactions
        │   ├── data/
        │   │   ├── datasources/
        │   │   ├── models/    # MessageModel (mapped straight from sockets)
        │   │   └── repositories/
        │   └── presentation/
        │       ├── bloc/      # ChatBloc
        │       ├── screens/   # LiveChatRoomScreen
        │       └── widgets/   # ChatBubble
        │
        ├── saved_places/      # Address Management Hub (Replaces old 'help' tab)
        │   ├── data/
        │   │   ├── datasources/ # Local database (Isar/Hive) or remote sync endpoints
        │   │   ├── models/    # SavedAddressModel
        │   │   └── repositories/
        │   ├── domain/
        │   │   └── repositories/
        │   └── presentation/
        │       ├── bloc/      # SavedPlacesBloc
        │       ├── screens/   # FavoritesManagementScreen
        │       └── widgets/   # AddressTile, AddPlaceBottomSheet
        │
        ├── activity/          # Past trip history
        │   ├── data/
        │   │   ├── models/    # HistoricTripSummaryModel
        │   │   └── repositories/
        │   └── presentation/
        │       ├── bloc/      # ActivityHistoryBloc
        │       ├── screens/   # TripHistoryScreen
        │       └── widgets/   # PastTripRowItem
        │
        └── profile/           # User/Driver Account details
            └── presentation/
                ├── bloc/      # ProfileBloc
                └── screens/   # ProfileScreen, SettingsScreen
2. Navigation & Layout Adjustments (Passenger App)
[ ] Remove Center FAB Implementation: Eliminate the floating action button and all its associated interaction code completely.

[ ] Refactor Bottom Tab Bar: Establish a clean, balanced 4-tab bar layout: [Home] [Activity] [Saved Places] [Profile].

[ ] Rebuild Home Dashboard Layout: Implement a professional, modern UI matching the exact structural flow:

Plaintext
┌────────────────────────────────────────┐
│  EasyRide                    [Bell_Icon]│ <── Header
│  Ready to ride today?                  │
│  📍 Zamboanga City                     │ <── Local city/area context
├────────────────────────────────────────┤
│  🔍 Enter destination                  │ <── Primary, prominent action bar
├────────────────────────────────────────┤
│  Quick Shortcuts                       │
│  ┌──────────┐┌──────────┐┌──────────┐  │ <── Horizontal scrollable list (Max 5)
│  │ 🏠 Home  ││ 💼 Work  ││ 🏫 School│  │ <── 1-Tap fast instant booking actions
│  └──────────┘└──────────┘└──────────┘  │
├────────────────────────────────────────┤
│                                        │
│          ✨ Where to?                  │ <── Clean, professional empty state
│     Your recent trips will appear      │     (Replaces the white void without
│         here once you ride!            │      introducing fake/mock data)
│                                        │
└────────────────────────────────────────┘
[ ] Remove 'Add Saved Place' from Dashboard: Completely migrate all "Add/Edit" creation points out of the main dashboard to clean up the workspace.

3. Feature Behavior & Logic Overhauls
Saved Places Management Architecture
[ ] Enforce structural division between Quick Shortcuts (Dashboard) and Saved Places (Tab Bar):

Feature	Location	Capacity	Primary Purpose
Quick Shortcuts	Home Screen	Max 5 (Horizontal scrollable)	Frictionless speed. 1-tap immediately captures coordinates and pushes to driver booking/matching phase.
Saved Places	Tab Bar	Unlimited	The organization management hub. Users can add, edit, or delete addresses, label custom spots (e.g., Gym, KCC Mall), or set up/reconfigure what "Home" and "Work" map to.
[ ] Fallback Deep-linking: If a user clicks an unset Quick Shortcut (e.g., "Home (Tap to set)"), deep-link them immediately to the Saved Places Tab to configure it.

Booking Flow Corrections
[ ] Fix Instant Test-Driver Bug: Stop the instant redirect behavior to a driver profile or "Book test driver" when clicking book ride—even if no drivers are online.

[ ] Fix Map Sticking: Ensure that searching/booking properly tracks match state-machines without locking or freezing the map layout when drivers are unavailable.

Data Fetching & Error Defect Resolution
[ ] Fix Activity Screen 404: Investigate and correct the endpoint routing/resource mismatch causing the 404 status code inside the Activity data layer.

[ ] Account Information Null Safety: If passenger account info fails to fetch, leave fields strictly blank. Do not use hardcoded string fallbacks (like "N/A", "John Doe"), ensuring true fetch states can be accurately determined.

4. Models Partitioning Enforcement
Data Models in External Core Packages (core_models, location_service)
User / DriverProfile / PassengerProfile (Required globally across authorization systems and endpoints).

Location / Coordinate (Calculated within pipelines, search interfaces, and fare modules).

Trip / TripStatus (The master state machine contract bound across both applications).

Data Models in Local Feature Layers (features/[feature_name]/data/models/)
BidRequestModel / CounterOfferModel (Isolated to the booking/matching lifecycle).

MessageModel / ChatRoomModel (Payload streams used only inside the live chat interface).

SavedAddressModel (Local data structures configured to fit local device engines/Isar schema structures).
