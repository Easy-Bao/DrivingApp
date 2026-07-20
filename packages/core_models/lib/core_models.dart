export 'src/models/driver_model.dart';
export 'src/models/notification_model.dart';
export 'src/models/place_model.dart';
export 'src/models/ride_history_model.dart';
export 'src/models/ride_status_model.dart';
export 'src/models/ride_update_model.dart';
export 'src/models/route_model.dart';
export 'src/models/heatmap_cell_model.dart';
export 'src/models/fare_result_model.dart';
export 'src/models/waypoint_model.dart';
export 'src/models/route_sequence_result_model.dart';
export 'src/safe_parse.dart';

export 'src/repositories/driver_repository.dart';
export 'src/repositories/passenger_home_repository.dart';
export 'src/repositories/track_repository.dart';
export 'src/repositories/dashboard_repository.dart';
export 'src/repositories/ride_repository.dart';

export 'src/errors/exceptions.dart';
export 'src/errors/failures.dart';
export 'src/errors/error_handler.dart';
/// TODO: CORE_MODELS MONOLITH DECONSTRUCTION
///
/// 1. [DECOUPLING REPOSITORIES] Remove the `repositories/` directory completely from this package. 
///    Domain abstract repositories (like `driver_repository.dart` or `ride_repository.dart`) 
///    must be migrated to the `domain/repositories/` folder of their respective feature packages 
///    (`driver_services`, `passenger_services`, etc.) to obey the FFP pattern.
///
/// 2. [MODEL MIGRATION BOUNDARIES] Audit the `models/` folder. A truly shared "core" package should 
///    only hold data structures utilized across *multiple* distinct packages (e.g., universal objects like 
///    `place_model.dart` or `waypoint_model.dart`). Highly isolated structures like `driver_model.dart` 
///    should live inside the `features/driver/data/models/` directory of the driver package.
///
/// 3. [SEPARATE CORE ARCHITECTURE UTILS] Consider extracting the `errors/` directory (`exceptions.dart`, 
///    `failures.dart`) and `safe_parse.dart` into a distinct, specialized utility package named 
///    `core_utils` or `core_network`. Mixing basic parsing primitives and base error hierarchies 
///    inside a package explicitly named `core_models` violates clean semantic domain naming.
///
/// 4. [EXPORT CLEANUP] Refactor the central `lib/core_models.dart` file. Remove public exposure 
///    for all displaced models and repositories so that consumer features compile strictly using 
///    their localized, feature-first boundaries.
