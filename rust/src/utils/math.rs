/// Calculate the great-circle distance between two points in kilometers.
/// Pure math — no IO, no allocation, maximum speed.
pub fn haversine_distance(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    const EARTH_RADIUS_KM: f64 = 6371.0;

    let d_lat = (lat2 - lat1).to_radians();
    let d_lng = (lng2 - lng1).to_radians();

    let a = (d_lat / 2.0).sin().powi(2)
        + lat1.to_radians().cos() * lat2.to_radians().cos() * (d_lng / 2.0).sin().powi(2);

    let c = 2.0 * a.sqrt().asin();
    EARTH_RADIUS_KM * c
}
