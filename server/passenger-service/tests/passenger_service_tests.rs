/// Passenger Service Tests: validates ride type parsing, repository CRUD, and API handlers.
mod mock_setup {
    pub use passenger_service::passenger::domain::*;
    pub use passenger_service::passenger::handlers::*;
    pub use passenger_service::passenger::models::*;
    pub use passenger_service::passenger::repository::*;
}

use axum::extract::State;
use axum::response::IntoResponse;
use axum::Json;
use mock_setup::*;
use std::str::FromStr;
use std::sync::Arc;
use uuid::Uuid;

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

#[tokio::test]
async fn test_in_memory_repository_operations() {
    let repo = InMemoryPassengerRepository::new();

    let create_req = CreatePassengerRequest {
        name: "Test Passenger".to_string(),
        email: "test@bao.com".to_string(),
        phone: "+639123456789".to_string(),
        password: "password123".to_string(),
        preferred_ride_type: Some("share-bao".to_string()),
    };
    let passenger = repo.create_passenger(create_req.clone()).await.unwrap();
    assert_eq!(passenger.name, "Test Passenger");
    assert_eq!(passenger.email, "test@bao.com");
    assert_eq!(passenger.preferred_ride_type, Some(RideType::ShareBao));
    assert!(bcrypt::verify("password123", &passenger.password_hash).unwrap());

    let dup_err = repo.create_passenger(create_req).await;
    assert!(dup_err.is_err());
    assert!(dup_err.unwrap_err().to_string().contains("already exists"));

    let fetched = repo.get_passenger(passenger.id).await.unwrap().unwrap();
    assert_eq!(fetched.id, passenger.id);
    assert_eq!(fetched.name, "Test Passenger");

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

    let rides = repo.get_passenger_rides(passenger.id).await.unwrap();
    assert_eq!(rides.len(), 2);
    assert_eq!(rides[0].ride_type, RideType::SoloRide);
    assert_eq!(rides[1].ride_type, RideType::ShareBao);
}

#[tokio::test]
async fn test_http_handlers() {
    let repo = Arc::new(InMemoryPassengerRepository::new());
    let state = State(repo.clone() as Arc<dyn PassengerRepository>);

    let create_payload = CreatePassengerRequest {
        name: "Alice Smith".to_string(),
        email: "alice@bao.com".to_string(),
        phone: "+639999999999".to_string(),
        password: "password123".to_string(),
        preferred_ride_type: Some("solo-ride".to_string()),
    };
    let create_res = create_passenger(state.clone(), Json(create_payload)).await.into_response();
    assert_eq!(create_res.status(), axum::http::StatusCode::CREATED);

    let body_bytes = axum::body::to_bytes(create_res.into_body(), 1024 * 16).await.unwrap();
    let passenger: Passenger = serde_json::from_slice(&body_bytes).unwrap();
    let passenger_id = passenger.id;

    let login_payload = LoginRequest {
        email: "alice@bao.com".to_string(),
        password: "password123".to_string(),
    };
    let login_res = login(state.clone(), Json(login_payload)).await.into_response();
    assert_eq!(login_res.status(), axum::http::StatusCode::OK);

    let invalid_login_payload = LoginRequest {
        email: "alice@bao.com".to_string(),
        password: "wrong_password".to_string(),
    };
    let invalid_login_res = login(state.clone(), Json(invalid_login_payload)).await.into_response();
    assert_eq!(invalid_login_res.status(), axum::http::StatusCode::UNAUTHORIZED);

    let get_res = get_passenger(state.clone(), axum::extract::Path(passenger_id)).await.into_response();
    assert_eq!(get_res.status(), axum::http::StatusCode::OK);

    let get_nonexistent = get_passenger(state.clone(), axum::extract::Path(Uuid::new_v4())).await.into_response();
    assert_eq!(get_nonexistent.status(), axum::http::StatusCode::NOT_FOUND);

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

    let history_res = get_passenger_rides(state.clone(), axum::extract::Path(passenger_id)).await.into_response();
    assert_eq!(history_res.status(), axum::http::StatusCode::OK);

    let body_bytes = axum::body::to_bytes(history_res.into_body(), 1024 * 16).await.unwrap();
    let rides: Vec<RideRequest> = serde_json::from_slice(&body_bytes).unwrap();
    assert_eq!(rides.len(), 1);
    assert_eq!(rides[0].ride_type, RideType::SoloRide);
}
