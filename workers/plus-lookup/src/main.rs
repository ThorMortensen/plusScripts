use clap::Parser;
use graphql_client::reqwest::post_graphql;
use graphql_client::GraphQLQuery;
use reqwest::header::{HeaderMap, HeaderValue, ACCEPT, CONTENT_TYPE};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value as JSON;
use std::error::Error;
use std::fmt::Display;
use std::io;
use std::process::Command;
use tokio::main;

#[derive(thiserror::Error, Debug)]
enum LookupError {
    #[error("LookupError::IOError: {0}")]
    IOError(#[from] io::Error),

    #[error("LookupError::ReqwestError: {0}")]
    ReqwestError(#[from] reqwest::Error),

    #[error("LookupError::NoData {what}")]
    NoData { what: String },
    // #[error("CustomError::Offline {0}")]
    // Offline(std::sync::Arc<str>),

    // #[error("CustomError::Onomondo {0}")]
    // Onomondo(#[from] Box<dyn std::error::Error>),
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None, )]
struct Args {
    #[arg(short, long, requires_all = ["app", "rootfs", "kernel"])]
    bootloader: Option<String>,

    #[arg(short, long, requires_all = ["bootloader", "rootfs", "kernel"])]
    app: Option<String>,

    #[arg(short, long, requires_all = ["bootloader", "app", "kernel"])]
    rootfs: Option<String>,

    #[arg(short, long, requires_all = ["bootloader", "app", "rootfs"])]
    kernel: Option<String>,

    #[arg(short, long)]
    device_id: Option<String>,
}

#[derive(Default, Debug, Serialize)]
struct DeviceData {
    fw_id: Option<String>,
    rg_name: Option<String>,
    rg_id: Option<String>,
    sim_id: Option<String>,
    vin: Option<String>,
    config_name: Option<String>,
    vehicle_id: Option<String>,
}

// impl Display for DeviceData {
//     fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
//         let mut data = String::new();
//         if let Some(fw_id) = &self.fw_id {
//             data.push_str(&format!("fw_id: {}\n", fw_id));
//         }
//         if let Some(rg_name) = &self.rg_name {
//             data.push_str(&format!("rg_name: {}\n", rg_name));
//         }
//         if let Some(rg_id) = &self.rg_id {
//             data.push_str(&format!("rg_id: {}\n", rg_id));
//         }
//         if let Some(sim_id) = &self.sim_id {
//             data.push_str(&format!("sim_id: {}\n", sim_id));
//         }
//         if let Some(vin) = &self.vin {
//             data.push_str(&format!("vin: {}\n", vin));
//         }
//         if let Some(config_name) = &self.config_name {
//             data.push_str(&format!("config_name: {}\n", config_name));
//         }
//         write!(f, "{}", data)
//     }
// }

fn get_client(jwt_token: &str) -> Result<Client, LookupError> {
    let mut headers = HeaderMap::new();
    headers.insert(
        "X-Organization-Namespace",
        HeaderValue::from_static("cctech:workshop"),
    );
    headers.insert(ACCEPT, HeaderValue::from_static("application/json"));
    headers.insert(
        "Authorization",
        HeaderValue::from_str(&format!("Bearer {}", jwt_token)).unwrap(),
    );
    headers.insert("Origin", HeaderValue::from_static("device-station"));

    Ok(Client::builder()
        .user_agent("graphql-rust/0.10.0")
        .default_headers(headers)
        .build()?)
}

#[allow(dead_code)]
async fn get_rollout_group(jwt_token: &str, fw_id: &str) -> Result<String, LookupError> {
    #[derive(GraphQLQuery)]
    #[graphql(
        schema_path = "res/scma.json",
        query_path = "res/query",
        response_derives = "Debug"
    )]
    struct RolloutGroups;

    let client = get_client(jwt_token)?;

    let rg_response_body = post_graphql::<RolloutGroups, _>(
        &client,
        "https://api.connectedcars.io/graphql",
        rollout_groups::Variables,
    )
    .await?;

    let rg_list: rollout_groups::ResponseData =
        rg_response_body.data.ok_or(LookupError::NoData {
            what: "No data in rollout_groups::ResponseData".into(),
        })?;

    let rg_id = rg_list
        .firmware_rollout_groups
        .items
        .iter()
        .find(|rg| rg.firmware_release_id == fw_id);

    Ok(rg_id.unwrap().id.clone())
}

async fn get_fw_id(
    jwt_token: &str,
    app_sha: String,
    bootloader_sha: String,
    rootfs_sha: String,
    kernel_sha: String,
) -> Result<Option<String>, LookupError> {
    #[derive(GraphQLQuery)]
    #[graphql(
        schema_path = "res/scma.json",
        query_path = "res/query",
        response_derives = "Debug"
    )]
    struct ListFirmwares;

    let client = get_client(jwt_token)?;

    let fw_list_response_body = post_graphql::<ListFirmwares, _>(
        &client,
        "https://api.connectedcars.io/graphql",
        list_firmwares::Variables,
    )
    .await?;

    let fw_list: list_firmwares::ResponseData =
        fw_list_response_body.data.expect("missing response data");

    let fw_id = fw_list.firmware_releases.iter().find(|fw| {
        fw.app == app_sha
            && fw.bootloader == bootloader_sha
            && fw.rootfs == rootfs_sha
            && fw.kernel == kernel_sha
    });

    Ok(fw_id.map(|fw| fw.id.clone()))
}

async fn get_device_info(jwt_token: &str, di: &str) -> Result<DeviceData, LookupError> {
    #[derive(GraphQLQuery)]
    #[graphql(
        schema_path = "res/scma.json",
        query_path = "res/query",
        response_derives = "Debug"
    )]
    struct DeviceInfo;
    let mut device_data = DeviceData::default();

    let client = get_client(jwt_token)?;

    let device_info_vars = device_info::Variables {
        unit_serial: di.to_string(),
    };

    let device_info_response_body = post_graphql::<DeviceInfo, _>(
        &client,
        "https://api.connectedcars.io/graphql",
        device_info_vars,
    );

    let device_info: device_info::ResponseData = device_info_response_body.await?.data.unwrap();

    if let Some(unit) = device_info.unit {
        if let Some(fw) = unit.firmware_rollout_group {
            device_data.rg_id = Some(fw.id.clone());
            device_data.rg_name = Some(fw.name);
        }
        if let Some(sim) = unit.sim_id {
            device_data.sim_id = Some(sim);
        }
        if let Some(vin) = unit.vin {
            device_data.vin = Some(vin.vin);
        }
        if let Some(vehicle) = unit.vehicle {
            device_data.vehicle_id = Some(vehicle.id);
        }
        if let Some(config) = unit.config {
            device_data.config_name = config
                .config
                .get("name")
                .and_then(serde_json::Value::as_str)
                .map(String::from);
        }
    }

    Ok(device_data)
}

pub async fn get_jwt() -> Result<String, Box<dyn Error>> {
    #[derive(Serialize)]
    struct Data {
        token: String,
    }

    #[derive(Deserialize)]
    struct ResponseData {
        token: String,
    }

    let output = Command::new("gcloud")
        .args(["auth", "print-identity-token"])
        .output()?;

    if !output.status.success() {
        eprintln!("failed to get token from gcloud");
        return Err("failed to get token from gcloud".into());
    }

    let token = String::from_utf8(output.stdout)?.trim().to_string();
    let data = Data { token };

    let mut headers = HeaderMap::new();
    headers.insert(
        "X-Organization-Namespace",
        HeaderValue::from_static("cctech:workshop"),
    );
    headers.insert(ACCEPT, HeaderValue::from_static("application/json"));
    headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));

    let client = reqwest::Client::new();
    let res = client
        .post("https://auth-api.connectedcars.io/auth/login/googleConverter")
        .headers(headers)
        .json(&data)
        .send()
        .await?
        .json::<ResponseData>()
        .await?;

    Ok(res.token)
}

#[main]
async fn main() {
    let args = Args::parse();
    let mut fw_id = None;
    let mut device_data = DeviceData::default();
    let token = get_jwt().await.unwrap();

    if let Some(di) = &args.device_id {
        device_data = get_device_info(&token, di).await.unwrap();
    }

    if args.app.is_some() {
        let bootloader_sha = args.bootloader.unwrap();
        let app_sha = args.app.unwrap();
        let rootfs_sha = args.rootfs.unwrap();
        let kernel_sha = args.kernel.unwrap();
        fw_id = get_fw_id(&token, app_sha, bootloader_sha, rootfs_sha, kernel_sha)
            .await
            .unwrap();
    }

    device_data.fw_id = fw_id;
    println!("{}", serde_json::to_string_pretty(&device_data).unwrap());
}