use reqwest;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let token = std::env::var("MAPBOX_PUBLIC_TOKEN").unwrap_or_else(|_| "pk.eyJ1IjoieHlyZWx0ZW56IiwiYSI6ImNsdzd4NnZ5dTB2NGoaMnBwM2M0d3Z5ajAifQ.XYZ".to_string());
    
    // Using a public token from flutter config if possible, or just print the URL.
    println!("https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/tilequery/123.4370,7.8307.json?radius=1000&limit=50&layers=poi_label&access_token=TOKEN");
    Ok(())
}
