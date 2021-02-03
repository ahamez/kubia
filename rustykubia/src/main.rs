use actix_web::{get, App, HttpRequest, HttpResponse, HttpServer, Responder};
use log::{info, warn, LevelFilter};
use simple_logger::SimpleLogger;
use std::ffi::OsString;

const VERSION: &str = "0.11.0";

#[get("/")]
async fn hello(req: HttpRequest) -> impl Responder {
    info!(
        "/ from {}",
        req.connection_info().remote_addr().unwrap_or("N/A")
    );

    let var = "KUBIA_FORTUNE_PATH";
    let fortune_path = match std::env::var(var) {
        Ok(val) => Some(val),
        Err(_) => None,
    };

    info!("Fortune path: {:?}", fortune_path);

    let no_fortune_for_you = "No fortune for you".to_string();
    let fortune = match fortune_path {
        Some(ref path) => std::fs::read_to_string(path).unwrap_or_else(|_err| {
            warn!("Cannot read {}", path);
            no_fortune_for_you
        }),
        None => no_fortune_for_you,
    };

    let vars = std::env::vars()
        .map(|(key, value)| format!("{}={} ", key, value))
        .collect::<Vec<String>>()
        .join(" | ");

    let resp = format!(
        "This is your host {} (version {}) ({} || {}), your IP is {} ({})\nEnv:\n{}\n\nHere's your fortune:\n {}",
        hostname::get()
            .unwrap_or(OsString::from("N/A"))
            .to_string_lossy(),
        VERSION,
        req.app_config().host(),
        req.connection_info().host(),
        req.connection_info().remote_addr().unwrap_or("N/A"),
        req.connection_info().realip_remote_addr().unwrap_or("N/A"),
        vars,
        fortune,
    );

    HttpResponse::Ok().body(resp.to_string())
}

#[get("/health")]
async fn health(req: HttpRequest) -> impl Responder {
    info!(
        "/health from {}",
        req.connection_info().remote_addr().unwrap_or("N/A")
    );

    HttpResponse::Ok()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    SimpleLogger::new()
        .with_level(LevelFilter::Info)
        .init()
        .unwrap();

    HttpServer::new(|| App::new().service(hello).service(health))
        .bind("0.0.0.0:8080")?
        .run()
        .await
}
