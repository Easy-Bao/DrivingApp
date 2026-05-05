use std::time::Duration;

use crate::domain::models::{
    CoordPair, MapboxDirectionsResponse, MapboxFeature, MapboxGeocodingResponse, MapboxProperties,
    MapboxRoute, RustPlaceResult, RustRouteResult,
};
use crate::shared::math::haversine_distance;
use once_cell::sync::Lazy;

static HTTP_CLIENT: Lazy<reqwest::Client> = Lazy::new(|| {
    reqwest::Client::builder()
        .timeout(Duration::from_secs(10))
        .build()
        .unwrap()
});

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

        let lat_offset = 50.0 / 111.0;
        let lng_offset = 50.0 / (111.0 * lat.to_radians().cos());

        let min_lng = lng - lng_offset;
        let min_lat = lat - lat_offset;
        let max_lng = lng + lng_offset;
        let max_lat = lat + lat_offset;

        url.push_str(&format!(
            "&bbox={},{},{},{}",
            min_lng, min_lat, max_lng, max_lat
        ));
    }

    let resp: MapboxGeocodingResponse = HTTP_CLIENT.get(&url).send().await?.json().await?;

    let results = resp
        .features
        .into_iter()
        .map(|f| {
            let place_lat = f.center.get(1).copied().unwrap_or(0.0);
            let place_lng = f.center.first().copied().unwrap_or(0.0);

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

    let resp: MapboxGeocodingResponse = HTTP_CLIENT.get(&url).send().await?.json().await?;

    let result: Option<RustPlaceResult> =
        resp.features
            .into_iter()
            .next()
            .map(|f: MapboxFeature| RustPlaceResult {
                id: f.id.unwrap_or_default(),
                name: f.text.unwrap_or_default(),
                full_address: f.place_name.unwrap_or_default(),
                latitude: lat,
                longitude: lng,
                category: f.properties.and_then(|p: MapboxProperties| p.category),
                distance_km: None,
            });

    Ok(result)
}

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

    let resp: MapboxDirectionsResponse = HTTP_CLIENT.get(&url).send().await?.json().await?;

    let result: Option<RustRouteResult> =
        resp.routes.into_iter().next().map(|route: MapboxRoute| {
            let points: Vec<CoordPair> = route
                .geometry
                .coordinates
                .into_iter()
                .map(|c: Vec<f64>| CoordPair {
                    lng: c.first().copied().unwrap_or(0.0),
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

/// Extract all dynamic Points of Interest from Mapbox vector tiles within a radius
pub async fn get_nearby_pois(
    token: &str,
    lat: f64,
    lng: f64,
    radius_meters: i32,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    let url = format!(
        "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/tilequery/{},{}.json?radius={}&limit=50&layers=poi_label&access_token={}",
        lng, lat, radius_meters, token
    );

    let resp: serde_json::Value = HTTP_CLIENT.get(&url).send().await?.json().await?;

    let mut results = Vec::new();

    if let Some(features) = resp.get("features").and_then(|f| f.as_array()) {
        for f in features {
            let geom = f.get("geometry");
            let props = f.get("properties");

            if let (Some(geom), Some(props)) = (geom, props) {
                let coords = geom.get("coordinates").and_then(|c| c.as_array());
                let p_lng = coords
                    .and_then(|c| c.first())
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);
                let p_lat = coords
                    .and_then(|c| c.get(1))
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);

                let name = props
                    .get("name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("Unknown")
                    .to_string();

                let category = props
                    .get("type")
                    .and_then(|v| v.as_str())
                    .unwrap_or("poi")
                    .to_string();

                let distance_m = props
                    .get("tilequery")
                    .and_then(|t| t.get("distance"))
                    .and_then(|v| v.as_f64())
                    .unwrap_or(0.0);

                if name.trim().is_empty() || name == "Unknown" {
                    continue;
                }

                results.push(RustPlaceResult {
                    id: format!("poi_{}_{}", p_lat, p_lng),
                    name: name.clone(),
                    full_address: format!("{}, {}", name, category),
                    latitude: p_lat,
                    longitude: p_lng,
                    category: Some(category),
                    distance_km: Some(distance_m / 1000.0),
                });
            }
        }
    }

    results.sort_by(|a, b| {
        a.distance_km
            .unwrap_or(f64::MAX)
            .partial_cmp(&b.distance_km.unwrap_or(f64::MAX))
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    Ok(results)
}
