/// FEATURE-FIRST PACKAGE (FFP) ARCHITECTURE & SERVICES
library;
///
/// 1. [CORE UTILS] Create a `src/core/network/` folder. Extract the shared HTTP client configurations
///    and interceptors into `base_api_client.dart` to decouple core engine config from features.
///
/// 2. [FEATURE SEPARATION] Initialize the structural directories inside `src/features/`:
///    - `src/features/auth/`
///    - `src/features/passenger_profile/`
///    - `src/features/bidding/`
///
/// 3. [CLEAN ARCHITECTURE SPLIT - DATA LAYER] For each feature, create `data/datasources/` directories.
///    - Breakdown `PassengerApiService` and move the respective split methods into:
///      * `auth_remote_datasource.dart`
///      * `passenger_remote_datasource.dart`
///      * `bidding_remote_datasource.dart`
///
/// 4. [CLEAN ARCHITECTURE SPLIT - DOMAIN LAYER] For each feature, add `domain/entities/` and `domain/repositories/`.
///    - Define abstract interfaces (e.g., `BiddingRepository`) in the domain layer to separate business contracts from framework implementation.
///    - Create implementation classes (e.g., `BiddingRepositoryImpl`) inside `data/repositories/`.
///
/// 5. [STATE STATE IMPLEMENTATION] Move `BidSessionService` into the `bidding` feature under either
///    `domain/` or a `presentation/` folder depending on whether it functions as a pure business controller
///    or a state management delegate.
///
/// 6. [MODEL CONVERSION] Transition the raw inline types into data layer objects inside `data/models/`.
///    - Relocate and convert `BidSessionTrip` and `DriverMatchResult` into fully serializable data models
///      (e.g., generating `.freezed.dart` or `.g.dart` data schemas matching the `chat_service` structure).
export 'src/auth_api_service.dart';
export 'src/background_telemetry_service.dart';
export 'src/base_api_client.dart';
export 'src/bidding_api_service.dart';
export 'src/passenger_api_service.dart';
export 'src/telemetry_api_service.dart';
export 'src/trip_api_service.dart';
