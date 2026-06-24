use std::sync::LazyLock;
use std::time::Duration;

use crate::dto::mapbox_dto::{
    MapboxDirectionsResponse, MapboxFeature, MapboxGeocodingResponse, MapboxProperties, MapboxRoute,
};
use crate::models::map_models::{CoordPair, RustPlaceResult, RustRouteResult};
use crate::shared::math::haversine_distance;

static HTTP_CLIENT: LazyLock<reqwest::Client> = LazyLock::new(|| {
    reqwest::Client::builder()
        .timeout(Duration::from_secs(10))
        .build()
        .unwrap()
});

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
    let url = format!(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/{}.json",
        encoded_query
    );

    let mut request =
        HTTP_CLIENT
            .get(&url)
            .query(&[("access_token", token), ("limit", "8"), ("language", "en")]);

    if let (Some(lat), Some(lng)) = (proximity_lat, proximity_lng) {
        let lat_offset = 50.0 / 111.0;
        let lng_offset = 50.0 / (111.0 * lat.to_radians().cos());

        let min_lng = lng - lng_offset;
        let min_lat = lat - lat_offset;
        let max_lng = lng + lng_offset;
        let max_lat = lat + lat_offset;

        request = request.query(&[
            ("proximity", format!("{},{}", lng, lat)),
            (
                "bbox",
                format!("{},{},{},{}", min_lng, min_lat, max_lng, max_lat),
            ),
        ]);
    }

    let resp: MapboxGeocodingResponse = request.send().await?.json().await?;

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

pub async fn reverse_geocode(
    token: &str,
    lat: f64,
    lng: f64,
) -> anyhow::Result<Option<RustPlaceResult>> {
    let url = format!(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/{},{}.json",
        lng, lat
    );

    let resp: MapboxGeocodingResponse = HTTP_CLIENT
        .get(&url)
        .query(&[("access_token", token), ("limit", "1"), ("language", "en")])
        .send()
        .await?
        .json()
        .await?;

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

pub async fn get_route(
    token: &str,
    origin_lat: f64,
    origin_lng: f64,
    dest_lat: f64,
    dest_lng: f64,
) -> anyhow::Result<Option<RustRouteResult>> {
    let url = format!(
        "https://api.mapbox.com/directions/v5/mapbox/driving/{},{};{},{}",
        origin_lng, origin_lat, dest_lng, dest_lat
    );

    let resp: MapboxDirectionsResponse = HTTP_CLIENT
        .get(&url)
        .query(&[
            ("access_token", token),
            ("geometries", "geojson"),
            ("overview", "full"),
        ])
        .send()
        .await?
        .json()
        .await?;

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

pub async fn get_nearby_pois(
    token: &str,
    lat: f64,
    lng: f64,
    radius_meters: i32,
) -> anyhow::Result<Vec<RustPlaceResult>> {
    let url = format!(
        "https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/tilequery/{},{}.json",
        lng, lat
    );

    let resp: serde_json::Value = HTTP_CLIENT
        .get(&url)
        .query(&[
            ("radius", radius_meters.to_string().as_str()),
            ("limit", "50"),
            ("layers", "poi_label"),
            ("access_token", token),
        ])
        .send()
        .await?
        .json()
        .await?;

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
        let dist_a = a.distance_km.unwrap_or(f64::MAX);
        let dist_b = b.distance_km.unwrap_or(f64::MAX);
        dist_a.total_cmp(&dist_b)
    });

    Ok(results)
}
