#![allow(clippy::all, warnings)]
pub struct ListFirmwares;
pub mod list_firmwares {
    #![allow(dead_code)]
    use std::result::Result;
    pub const OPERATION_NAME: &str = "ListFirmwares";
    pub const QUERY : & str = "query ListFirmwares {\n  firmwareReleases {\n    id\n    app\n    appBranch\n    kernel\n    kernelBranch\n    bootloader\n    bootloaderBranch\n    rootfs\n    rootfsBranch\n    skipDeltas\n    firmwareCapabilities\n    testResults {\n      jobPreset\n      result\n    }   \n  }\n}\n\nquery RolloutGroups {\n  firmwareRolloutGroups(provider: cc, first: 1000) {\n    items {\n      id\n      name\n      firmwareReleaseId\n    }\n  }\n}\n\nquery DeviceInfo($unit_serial: String!){\n  unit(provider: cc, unitSerial: $unit_serial) {\n    firmwareRolloutGroup{\n      id\n      name\n    }\n    simProvider\n    simProviderLink\n    stickerId\n    vehicle{id}\n    vin{vin}\n    config{config}\n  }\n}\n" ;
    use super::*;
    use serde::{Deserialize, Serialize};
    #[allow(dead_code)]
    type Boolean = bool;
    #[allow(dead_code)]
    type Float = f64;
    #[allow(dead_code)]
    type Int = i64;
    #[allow(dead_code)]
    type ID = String;
    #[derive(Serialize)]
    pub struct Variables;
    #[derive(Deserialize)]
    pub struct ResponseData {
        #[serde(rename = "firmwareReleases")]
        pub firmware_releases: Vec<ListFirmwaresFirmwareReleases>,
    }
    #[derive(Deserialize)]
    pub struct ListFirmwaresFirmwareReleases {
        pub id: ID,
        pub app: String,
        #[serde(rename = "appBranch")]
        pub app_branch: String,
        pub kernel: String,
        #[serde(rename = "kernelBranch")]
        pub kernel_branch: String,
        pub bootloader: String,
        #[serde(rename = "bootloaderBranch")]
        pub bootloader_branch: String,
        pub rootfs: String,
        #[serde(rename = "rootfsBranch")]
        pub rootfs_branch: String,
        #[serde(rename = "skipDeltas")]
        pub skip_deltas: Boolean,
        #[serde(rename = "firmwareCapabilities")]
        pub firmware_capabilities: Option<Vec<String>>,
        #[serde(rename = "testResults")]
        pub test_results: Vec<ListFirmwaresFirmwareReleasesTestResults>,
    }
    #[derive(Deserialize)]
    pub struct ListFirmwaresFirmwareReleasesTestResults {
        #[serde(rename = "jobPreset")]
        pub job_preset: Option<String>,
        pub result: Option<String>,
    }
}
impl graphql_client::GraphQLQuery for ListFirmwares {
    type Variables = list_firmwares::Variables;
    type ResponseData = list_firmwares::ResponseData;
    fn build_query(variables: Self::Variables) -> ::graphql_client::QueryBody<Self::Variables> {
        graphql_client::QueryBody {
            variables,
            query: list_firmwares::QUERY,
            operation_name: list_firmwares::OPERATION_NAME,
        }
    }
}
pub struct RolloutGroups;
pub mod rollout_groups {
    #![allow(dead_code)]
    use std::result::Result;
    pub const OPERATION_NAME: &str = "RolloutGroups";
    pub const QUERY : & str = "query ListFirmwares {\n  firmwareReleases {\n    id\n    app\n    appBranch\n    kernel\n    kernelBranch\n    bootloader\n    bootloaderBranch\n    rootfs\n    rootfsBranch\n    skipDeltas\n    firmwareCapabilities\n    testResults {\n      jobPreset\n      result\n    }   \n  }\n}\n\nquery RolloutGroups {\n  firmwareRolloutGroups(provider: cc, first: 1000) {\n    items {\n      id\n      name\n      firmwareReleaseId\n    }\n  }\n}\n\nquery DeviceInfo($unit_serial: String!){\n  unit(provider: cc, unitSerial: $unit_serial) {\n    firmwareRolloutGroup{\n      id\n      name\n    }\n    simProvider\n    simProviderLink\n    stickerId\n    vehicle{id}\n    vin{vin}\n    config{config}\n  }\n}\n" ;
    use super::*;
    use serde::{Deserialize, Serialize};
    #[allow(dead_code)]
    type Boolean = bool;
    #[allow(dead_code)]
    type Float = f64;
    #[allow(dead_code)]
    type Int = i64;
    #[allow(dead_code)]
    type ID = String;
    #[derive(Serialize)]
    pub struct Variables;
    #[derive(Deserialize)]
    pub struct ResponseData {
        #[serde(rename = "firmwareRolloutGroups")]
        pub firmware_rollout_groups: RolloutGroupsFirmwareRolloutGroups,
    }
    #[derive(Deserialize)]
    pub struct RolloutGroupsFirmwareRolloutGroups {
        pub items: Vec<RolloutGroupsFirmwareRolloutGroupsItems>,
    }
    #[derive(Deserialize)]
    pub struct RolloutGroupsFirmwareRolloutGroupsItems {
        pub id: ID,
        pub name: String,
        #[serde(rename = "firmwareReleaseId")]
        pub firmware_release_id: ID,
    }
}
impl graphql_client::GraphQLQuery for RolloutGroups {
    type Variables = rollout_groups::Variables;
    type ResponseData = rollout_groups::ResponseData;
    fn build_query(variables: Self::Variables) -> ::graphql_client::QueryBody<Self::Variables> {
        graphql_client::QueryBody {
            variables,
            query: rollout_groups::QUERY,
            operation_name: rollout_groups::OPERATION_NAME,
        }
    }
}
pub struct DeviceInfo;
pub mod device_info {
    #![allow(dead_code)]
    use std::result::Result;
    pub const OPERATION_NAME: &str = "DeviceInfo";
    pub const QUERY : & str = "query ListFirmwares {\n  firmwareReleases {\n    id\n    app\n    appBranch\n    kernel\n    kernelBranch\n    bootloader\n    bootloaderBranch\n    rootfs\n    rootfsBranch\n    skipDeltas\n    firmwareCapabilities\n    testResults {\n      jobPreset\n      result\n    }   \n  }\n}\n\nquery RolloutGroups {\n  firmwareRolloutGroups(provider: cc, first: 1000) {\n    items {\n      id\n      name\n      firmwareReleaseId\n    }\n  }\n}\n\nquery DeviceInfo($unit_serial: String!){\n  unit(provider: cc, unitSerial: $unit_serial) {\n    firmwareRolloutGroup{\n      id\n      name\n    }\n    simProvider\n    simProviderLink\n    stickerId\n    vehicle{id}\n    vin{vin}\n    config{config}\n  }\n}\n" ;
    use super::*;
    use serde::{Deserialize, Serialize};
    #[allow(dead_code)]
    type Boolean = bool;
    #[allow(dead_code)]
    type Float = f64;
    #[allow(dead_code)]
    type Int = i64;
    #[allow(dead_code)]
    type ID = String;
    type JSON = super::JSON;
    #[derive()]
    pub enum SimProvider {
        onomondo,
        telenor,
        tele2,
        Other(String),
    }
    impl ::serde::Serialize for SimProvider {
        fn serialize<S: serde::Serializer>(&self, ser: S) -> Result<S::Ok, S::Error> {
            ser.serialize_str(match *self {
                SimProvider::onomondo => "onomondo",
                SimProvider::telenor => "telenor",
                SimProvider::tele2 => "tele2",
                SimProvider::Other(ref s) => &s,
            })
        }
    }
    impl<'de> ::serde::Deserialize<'de> for SimProvider {
        fn deserialize<D: ::serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
            let s: String = ::serde::Deserialize::deserialize(deserializer)?;
            match s.as_str() {
                "onomondo" => Ok(SimProvider::onomondo),
                "telenor" => Ok(SimProvider::telenor),
                "tele2" => Ok(SimProvider::tele2),
                _ => Ok(SimProvider::Other(s)),
            }
        }
    }
    #[derive(Serialize)]
    pub struct Variables {
        pub unit_serial: String,
    }
    impl Variables {}
    #[derive(Deserialize)]
    pub struct ResponseData {
        pub unit: Option<DeviceInfoUnit>,
    }
    #[derive(Deserialize)]
    pub struct DeviceInfoUnit {
        #[serde(rename = "firmwareRolloutGroup")]
        pub firmware_rollout_group: Option<DeviceInfoUnitFirmwareRolloutGroup>,
        #[serde(rename = "simProvider")]
        pub sim_provider: Option<SimProvider>,
        #[serde(rename = "simProviderLink")]
        pub sim_provider_link: Option<String>,
        #[serde(rename = "stickerId")]
        pub sticker_id: String,
        pub vehicle: Option<DeviceInfoUnitVehicle>,
        pub vin: Option<DeviceInfoUnitVin>,
        pub config: Option<DeviceInfoUnitConfig>,
    }
    #[derive(Deserialize)]
    pub struct DeviceInfoUnitFirmwareRolloutGroup {
        pub id: ID,
        pub name: String,
    }
    #[derive(Deserialize)]
    pub struct DeviceInfoUnitVehicle {
        pub id: ID,
    }
    #[derive(Deserialize)]
    pub struct DeviceInfoUnitVin {
        pub vin: String,
    }
    #[derive(Deserialize)]
    pub struct DeviceInfoUnitConfig {
        pub config: JSON,
    }
}
impl graphql_client::GraphQLQuery for DeviceInfo {
    type Variables = device_info::Variables;
    type ResponseData = device_info::ResponseData;
    fn build_query(variables: Self::Variables) -> ::graphql_client::QueryBody<Self::Variables> {
        graphql_client::QueryBody {
            variables,
            query: device_info::QUERY,
            operation_name: device_info::OPERATION_NAME,
        }
    }
}
