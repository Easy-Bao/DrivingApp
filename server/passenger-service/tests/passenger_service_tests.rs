mod mock_setup {
    pub use passenger_service::passenger::domain::*;
    pub use passenger_service::passenger::models::*;
    pub use passenger_service::passenger::repository::*;
    pub use passenger_service::passenger::handlers::*;
}

use axum::extract::State;
use axum::response::IntoResponse;
use axum::Json;
use mock_setup::*;
use std::str::FromStr;
use std::sync::Arc;
use uuid::Uuid;

/**
 * Verifies that the string representations of ride types ('solo-ride', 'share-bao', and their aliases)
 * are correctly deserialized/parsed into `RideType` enum variants.
 */
#[test]
fn test_ride_type_parsing() {
    assert_eq!(RideType::from_str("solo-ride").unwrap(), RideType::SoloRide);
    assert_eq!(RideType::from_str("Solo Ride").unwrap(), RideType::SoloRide);
    assert_eq!(RideType::from_str("solo_ride").unwrap(), RideType::SoloRide);
    assert_eq!(RideType::from_str("solo").unwrap(), RideType::SoloRide);

    assert_eq!(RideType::from_str("share-bao").unwrap(), RideType::ShareBao);
    assert_eq!(RideType::from_str("Share-Bao").unwrap(), RideType::ShareBao);
    assert_eq!(RideType::from_str("share bao").unwrap(), RideType::ShareBao);
    assert_eq!(RideType::from_str("share_bao").unwrap(), RideType::ShareBao);

    assert!(RideType::from_str("premium-bao").is_err());
    assert!(RideType::from_str("something-else").is_err());
}

/**
 * Verifies the repository operations under the thread-safe in-memory adapter.
 * Ensures standard CRUD, duplicate prevention, and validation rules work.
 */
#[tokio::test]
async fn test_in_memory_repository_operations() {
    let repo = InMemoryPassengerRepository::new();

    // 1. Create a passenger
    let create_req = CreatePassengerRequest {
        name: "Test Passenger".to_string(),
        email: "test@bao.com".to_string(),
        phone: "+639123456789".to_string(),
        preferred_ride_type: Some("share-bao".to_string()),
    };
    let passenger = repo.create_passenger(create_req.clone()).await.unwrap();
    assert_eq!(passenger.name, "Test Passenger");
    assert_eq!(passenger.email, "test@bao.com");
    assert_eq!(passenger.preferred_ride_type, Some(RideType::ShareBao));

    // 2. Prevent duplicate email registration
    let dup_err = repo.create_passenger(create_req).await;
    assert!(dup_err.is_err());
    assert!(dup_err.unwrap_err().to_string().contains("already exists"));

    // 3. Retrieve passenger
    let fetched = repo.get_passenger(passenger.id).await.unwrap().unwrap();
    assert_eq!(fetched.id, passenger.id);
    assert_eq!(fetched.name, "Test Passenger");

    // 4. Create a valid solo ride request
    let ride_req = CreateRideRequest {
        passenger_id: passenger.id,
        ride_type: "solo-ride".to_string(),
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: "Plaza Luz".to_string(),
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: "Robinson Supermarket".to_string(),
        fare: 65.0,
    };
    let ride = repo.create_ride_request(ride_req).await.unwrap();
    assert_eq!(ride.passenger_id, passenger.id);
    assert_eq!(ride.ride_type, RideType::SoloRide);
    assert_eq!(ride.pickup_name, "Plaza Luz");
    assert_eq!(ride.fare, 65.0);

    // 5. Create a valid share bao request
    let share_req = CreateRideRequest {
        passenger_id: passenger.id,
        ride_type: "share-bao".to_string(),
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: "Plaza Luz".to_string(),
        dropoff_latitude: 7.8295,
        dropoff_longitude: 123.4358,
        dropoff_name: "Bo's Coffee".to_string(),
        fare: 45.0,
    };
    let share_ride = repo.create_ride_request(share_req).await.unwrap();
    assert_eq!(share_ride.passenger_id, passenger.id);
    assert_eq!(share_ride.ride_type, RideType::ShareBao);
    assert_eq!(share_ride.fare, 45.0);

    // 6. Fail request for non-existent passenger
    let invalid_ride_req = CreateRideRequest {
        passenger_id: Uuid::new_v4(),
        ride_type: "solo-ride".to_string(),
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: "Plaza Luz".to_string(),
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: "Robinson Supermarket".to_string(),
        fare: 65.0,
    };
    let invalid_res = repo.create_ride_request(invalid_ride_req).await;
    assert!(invalid_res.is_err());

    // 7. Get passenger rides history
    let rides = repo.get_passenger_rides(passenger.id).await.unwrap();
    assert_eq!(rides.len(), 2);
    assert_eq!(rides[0].ride_type, RideType::SoloRide);
    assert_eq!(rides[1].ride_type, RideType::ShareBao);
}

/**
 * Verifies that HTTP handlers serialize and deserialize payloads properly
 * and return appropriate HTTP response status codes.
 */
#[tokio::test]
async fn test_http_handlers() {
    let repo = Arc::new(InMemoryPassengerRepository::new());
    let state = State(repo.clone() as Arc<dyn PassengerRepository>);

    // 1. Create Passenger Handler
    let create_payload = CreatePassengerRequest {
        name: "Alice Smith".to_string(),
        email: "alice@bao.com".to_string(),
        phone: "+639999999999".to_string(),
        preferred_ride_type: Some("solo-ride".to_string()),
    };
    let create_res = create_passenger(state.clone(), Json(create_payload)).await.into_response();
    assert_eq!(create_res.status(), axum::http::StatusCode::CREATED);

    // Decode response body to get ID
    let body_bytes = axum::body::to_bytes(create_res.into_body(), 1024 * 16).await.unwrap();
    let passenger: Passenger = serde_json::from_slice(&body_bytes).unwrap();
    let passenger_id = passenger.id;

    // 2. Get Passenger Handler
    let get_res = get_passenger(state.clone(), axum::extract::Path(passenger_id)).await.into_response();
    assert_eq!(get_res.status(), axum::http::StatusCode::OK);

    let get_nonexistent = get_passenger(state.clone(), axum::extract::Path(Uuid::new_v4())).await.into_response();
    assert_eq!(get_nonexistent.status(), axum::http::StatusCode::NOT_FOUND);

    // 3. Request Ride Handler (Solo-Ride)
    let ride_payload = CreateRideRequest {
        passenger_id,
        ride_type: "Solo Ride".to_string(),
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: "Plaza Luz".to_string(),
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: "Robinson Supermarket".to_string(),
        fare: 70.0,
    };
    let ride_res = request_ride(state.clone(), Json(ride_payload)).await.into_response();
    assert_eq!(ride_res.status(), axum::http::StatusCode::CREATED);

    // 4. Request Ride Handler (Invalid Type)
    let invalid_ride_payload = CreateRideRequest {
        passenger_id,
        ride_type: "premium".to_string(),
        pickup_latitude: 7.8286,
        pickup_longitude: 123.4361,
        pickup_name: "Plaza Luz".to_string(),
        dropoff_latitude: 7.8250,
        dropoff_longitude: 123.4380,
        dropoff_name: "Robinson Supermarket".to_string(),
        fare: 150.0,
    };
    let invalid_ride_res = request_ride(state.clone(), Json(invalid_ride_payload)).await.into_response();
    assert_eq!(invalid_ride_res.status(), axum::http::StatusCode::BAD_REQUEST);

    // 5. Get Rides History Handler
    let history_res = get_passenger_rides(state.clone(), axum::extract::Path(passenger_id)).await.into_response();
    assert_eq!(history_res.status(), axum::http::StatusCode::OK);

    let body_bytes = axum::body::to_bytes(history_res.into_body(), 1024 * 16).await.unwrap();
    let rides: Vec<RideRequest> = serde_json::from_slice(&body_bytes).unwrap();
    assert_eq!(rides.len(), 1);
    assert_eq!(rides[0].ride_type, RideType::SoloRide);
}
