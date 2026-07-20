/// PUBLIC EXPORT LAYER & DOMAIN CONTRACTS (passenger_services.dart)
library;
///
/// 1. [ENCAPSULATION] Clean up the public exports. Remove references to the old
///    monolithic `PassengerApiService` and `BidSessionService` once they are broken down.
///
/// 2. [DOMAIN BARRIER] Export only clean domain contracts and data models to the rest of the app:
///    - Export Feature Domain Repositories (e.g., `BiddingRepository`, `AuthRepository`).
///    - Export Safe Entities/Models (e.g., `BidSessionTrip`, `DriverMatchResult`).
///
/// 3. [IMPLEMENTATION HIDING] Do NOT export raw data sources (`BiddingRemoteDatasource`)
///    or network client configurations (`base_api_client.dart`). Keep the concrete data
///    layer implementations private inside `src/` to follow true Clean Architecture principles.
///
/// 4. [DEPENDENCY INJECTION PREPARATION] Export a unified initialization method or dependency
///    container configuration if needed, allowing the main app to easily inject the base
///    Dio client down into the split feature repositories.
export 'src/bid_session_service.dart';
export 'src/passenger_api_service.dart';
