use crate::core::models::{
    CoordPair, MapboxDirectionsResponse, MapboxGeocodingResponse, RustPlaceResult, RustRouteResult,
};
use crate::utils::math::haversine_distance;

// ─── Forward Geocoding ───────────────────────────────────────────────────────

/// Search for places using Mapbox Geocoding API.
pub async fn search_places(
    token: &str,
    query: &str,
    proximity_lat: Option<f64>,
    proximity_lng: Option<f64>,
    user_lat: Option<f64>,
    user_lng: Option<f64>,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    if query.trim().is_empty() {
        return Ok(vec![]);
    }

    let encoded_query = urlencoding::encode(query);
    let mut url = format!(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/{}.json?access_token={}&limit=8&language=en",
        encoded_query, token
    );

    if let (Some(lat), Some(lng)) = (proximity_lat, proximity_lng) {
        url.push_str(&format!("&proximity={},{}", lng, lat));
    }

    let client = reqwest::Client::new();
    let resp: MapboxGeocodingResponse = client.get(&url).send().await?.json().await?;

    let results = resp
        .features
        .into_iter()
        .map(|f| {
            let place_lat = f.center.get(1).copied().unwrap_or(0.0);
            let place_lng = f.center.get(0).copied().unwrap_or(0.0);

            let dist = match (user_lat, user_lng) {
                (Some(u_lat), Some(u_lng)) => {
                    Some(haversine_distance(u_lat, u_lng, place_lat, place_lng))
                }
                _ => None,
            };

            RustPlaceResult {
                id: f.id.unwrap_or_default(),
                name: f.text.unwrap_or_default(),
                full_address: f.place_name.unwrap_or_default(),
                latitude: place_lat,
                longitude: place_lng,
                category: f.properties.and_then(|p| p.category),
                distance_km: dist,
            }
        })
        .collect();

    Ok(results)
}

// ─── Reverse Geocoding ───────────────────────────────────────────────────────

/// Get place info from coordinates using Mapbox Geocoding API.
pub async fn reverse_geocode(
    token: &str,
    lat: f64,
    lng: f64,
) -> anyhow::Result<Option<RustPlaceResult>> {
    let url = format!(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/{},{}.json?access_token={}&limit=1&language=en",
        lng, lat, token
    );

    let client = reqwest::Client::new();
    let resp: MapboxGeocodingResponse = client.get(&url).send().await?.json().await?;

    let result = resp.features.into_iter().next().map(|f| RustPlaceResult {
        id: f.id.unwrap_or_default(),
        name: f.text.unwrap_or_default(),
        full_address: f.place_name.unwrap_or_default(),
        latitude: lat,
        longitude: lng,
        category: f.properties.and_then(|p| p.category),
        distance_km: None,
    });

    Ok(result)
}

// ─── Directions / Routing ────────────────────────────────────────────────────

/// Get a driving route between two points.
pub async fn get_route(
    token: &str,
    origin_lat: f64,
    origin_lng: f64,
    dest_lat: f64,
    dest_lng: f64,
) -> anyhow::Result<Option<RustRouteResult>> {
    let url = format!(
        "https://api.mapbox.com/directions/v5/mapbox/driving/{},{};{},{}?access_token={}&geometries=geojson&overview=full",
        origin_lng, origin_lat, dest_lng, dest_lat, token
    );

    let client = reqwest::Client::new();
    let resp: MapboxDirectionsResponse = client.get(&url).send().await?.json().await?;

    let result = resp.routes.into_iter().next().map(|route| {
        let points = route
            .geometry
            .coordinates
            .into_iter()
            .map(|c| CoordPair {
                lng: c.get(0).copied().unwrap_or(0.0),
                lat: c.get(1).copied().unwrap_or(0.0),
            })
            .collect();

        let summary = route
            .legs
            .and_then(|legs| legs.into_iter().next())
            .and_then(|leg| leg.summary)
            .unwrap_or_default();

        RustRouteResult {
            polyline_points: points,
            distance_km: route.distance / 1000.0,
            duration_seconds: route.duration,
            summary,
        }
    });

    Ok(result)
}
