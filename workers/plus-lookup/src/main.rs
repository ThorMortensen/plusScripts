use base64::engine::general_purpose::STANDARD_NO_PAD;
use base64::Engine;
use chrono::Utc;
use clap::Parser;
use graphql_client::reqwest::post_graphql;
use graphql_client::GraphQLQuery;
use reqwest::header::{HeaderMap, HeaderValue, ACCEPT, CONTENT_TYPE};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value as JSON;
use std::error::Error;
use std::path::PathBuf;
use std::process::Command;
use std::str::FromStr;
use std::{fs, io};
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
    #[arg(long, requires_all = ["app", "rootfs", "kernel"])]
    bootloader: Option<String>,

    #[arg(long, requires_all = ["bootloader", "rootfs", "kernel"])]
    app: Option<String>,

    #[arg(long, requires_all = ["bootloader", "app", "kernel"])]
    rootfs: Option<String>,

    #[arg(long, requires_all = ["bootloader", "app", "rootfs"])]
    kernel: Option<String>,

    #[arg(long)]
    device_id: Option<String>,

    #[arg(long)]
    release_id: Option<String>,

    #[arg(long)]
    jwt: bool,

    #[arg(long)]
    jwt_save: Option<PathBuf>,
}

impl Args {
    fn _make_debug_variant() -> Self {
        //--bootloader dbb049c90b2b307df14423a25816be2a8a990ddf
        //--app a7903582a2b09f269935668c08c582379a9c9461
        //--rootfs dbb049c90b2b307df14423a25816be2a8a990ddf
        //--kernel dbb049c90b2b307df14423a25816be2a8a990ddf
        //--device-id d5b0941d302d61d4
        //--release-id 888

        Self {
            bootloader: Some("dbb049c90b2b307df14423a25816be2a8a990ddf".into()),
            app: Some("a7903582a2b09f269935668c08c582379a9c9461".into()),
            rootfs: Some("dbb049c90b2b307df14423a25816be2a8a990ddf".into()),
            kernel: Some("dbb049c90b2b307df14423a25816be2a8a990ddf".into()),
            // device_id: Some("d5b0941d302d61d4".into()),
            // release_id: Some("888".into()),
            device_id: None,
            release_id: None,
            jwt: false,
            jwt_save: Some(PathBuf::from_str("/tmp/test-jwt.token").unwrap()),
        }
    }
}

#[derive(Default, Debug, Serialize)]
struct DeviceData {
    fw_id: Option<String>,
    rg_name: Option<String>,
    sticker_id: Option<String>,
    rg_id: Option<String>,
    sim_provider: Option<String>,
    sim_provider_link: Option<String>,
    sim_id: Option<String>,
    vin: Option<String>,
    config_name: Option<String>,
    vehicle_id: Option<String>,
    app_sha: Option<String>,
    app_branch: Option<String>,
    bootloader_sha: Option<String>,
    bootloader_branch: Option<String>,
    rootfs_sha: Option<String>,
    rootfs_branch: Option<String>,
    kernel_sha: Option<String>,
    kernel_branch: Option<String>,
}

#[derive(GraphQLQuery)]
#[graphql(
    schema_path = "res/scma.json",
    query_path = "res/query",
    response_derives = "Debug"
)]
struct ListFirmwares;

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
    // headers.insert("Origin", HeaderValue::from_static("device-station")); // THIS IS NOT WORKING !!

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
    let fw_list = get_fw_list(jwt_token).await?;

    let fw_id = fw_list.firmware_releases.iter().find(|fw| {
        fw.app == app_sha
            && fw.bootloader == bootloader_sha
            && fw.rootfs == rootfs_sha
            && fw.kernel == kernel_sha
    });

    Ok(fw_id.map(|fw| fw.id.clone()))
}

async fn get_fw_shas(jwt_token: &str, fw_id: String) -> Result<DeviceData, LookupError> {
    let fw_list = get_fw_list(jwt_token).await?;

    let fw_id = fw_list.firmware_releases.iter().find(|fw| fw.id == fw_id);

    if let Some(fw) = fw_id {
        Ok(DeviceData {
            app_sha: Some(fw.app.clone()),
            app_branch: Some(fw.app_branch.clone()),
            bootloader_sha: Some(fw.bootloader.clone()),
            bootloader_branch: Some(fw.bootloader_branch.clone()),
            rootfs_sha: Some(fw.rootfs.clone()),
            rootfs_branch: Some(fw.rootfs_branch.clone()),
            kernel_sha: Some(fw.kernel.clone()),
            kernel_branch: Some(fw.kernel_branch.clone()),
            ..Default::default()
        })
    } else {
        Ok(DeviceData::default())
    }
}

async fn get_fw_list(jwt_token: &str) -> Result<list_firmwares::ResponseData, LookupError> {
    let client = get_client(jwt_token)?;

    let fw_list_response_body = post_graphql::<ListFirmwares, _>(
        &client,
        "https://api.connectedcars.io/graphql",
        list_firmwares::Variables,
    )
    .await?;

    let fw_list: list_firmwares::ResponseData =
        fw_list_response_body.data.expect("missing response data");
    Ok(fw_list)
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
        if let Some(sim_provider) = unit.sim_provider {
            device_data.sim_provider = Some(format!("{:?}", sim_provider));
        }
        if let Some(sim_link) = unit.sim_provider_link {
            device_data.sim_provider_link = Some(sim_link.clone());
            let sim_id: &str = sim_link.split('/').last().unwrap_or("");
            device_data.sim_id = Some(sim_id.to_string());
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
        device_data.sticker_id = Some(unit.sticker_id);
    }

    Ok(device_data)
}

fn is_token_expired(jwt: &str) -> Result<bool, Box<dyn std::error::Error>> {
    let parts: Vec<&str> = jwt.split('.').collect();
    if parts.len() != 3 {
        return Err("Invalid JWT structure".into());
    }

    let payload = STANDARD_NO_PAD.decode(parts[1])?;
    let payload_str = String::from_utf8(payload)?;
    let payload_json: serde_json::Value = serde_json::from_str(&payload_str)?;

    if let Some(exp) = payload_json["exp"].as_u64() {
        let now = Utc::now().timestamp() as u64;
        Ok(exp <= now)
    } else {
        Err("Expiration time is missing in JWT".into())
    }
}

pub async fn get_jwt(save_path: Option<PathBuf>) -> Result<String, Box<dyn Error>> {
    if let Some(path) = save_path.as_ref() {
        if path.exists() {
            let token = fs::read_to_string(path)?;
            if !is_token_expired(&token)? {
                return Ok(token);
            }
        }
    }

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
        .output()
        .expect("failed to execute gcloud auth print-identity-token");

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

    if let Some(path) = save_path {
        fs::create_dir_all(path.parent().unwrap())?;
        fs::write(path, &res.token)?;
    }

    Ok(res.token)
}

#[main]
async fn main() {
    // let args = Args::_make_debug_variant();
    let args = Args::parse();

    let mut fw_id = None;
    let mut device_data = DeviceData::default();
    let token = match get_jwt(args.jwt_save).await {
        Ok(token) => token,
        Err(e) => {
            eprintln!("Did you forget to login?? Error: {}", e);
            return;
        }
    };

    if args.jwt {
        println!("{}", token);
        return;
    }

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

    if let Some(rid) = &args.release_id {
        let fw_data = get_fw_shas(&token, rid.to_string()).await.unwrap();
        device_data.app_sha = fw_data.app_sha;
        device_data.app_branch = fw_data.app_branch;
        device_data.bootloader_sha = fw_data.bootloader_sha;
        device_data.bootloader_branch = fw_data.bootloader_branch;
        device_data.rootfs_sha = fw_data.rootfs_sha;
        device_data.rootfs_branch = fw_data.rootfs_branch;
        device_data.kernel_sha = fw_data.kernel_sha;
        device_data.kernel_branch = fw_data.kernel_branch;
    }

    device_data.fw_id = fw_id;
    println!("{}", serde_json::to_string_pretty(&device_data).unwrap());
}
