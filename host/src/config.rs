use rand::{distributions::Alphanumeric, Rng};
use serde::{de::DeserializeOwned, Deserialize, Serialize};
use std::{fs, path::PathBuf};

/// Everything the desktop Settings tab can change, plus paired devices.
/// Stored at %APPDATA%\WinRelay\config.json.
#[derive(Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Config {
    // Connection
    pub port: u16,
    pub allow_internet: bool,
    pub ddns_host: String,
    pub pairing_token: String,
    // Security
    pub devices: Vec<Device>,
    pub hidden_apps: Vec<String>,
    pub idle_timeout_min: u32,
    pub lock_on_disconnect: bool,
    // Display and stealth
    pub stealth_default: bool,
    pub hide_taskbar_in_stealth: bool,
    pub fence_cursor: bool,
    pub max_fps: u32,
    pub jpeg_quality: u8,
    /// Semicolon-separated words matched against the display adapter name
    /// to find the virtual monitor.
    pub virtual_monitor_match: String,
    // Power
    pub keep_awake: bool,
    pub screens_off_on_start: bool,
    // General
    pub log_days: u32,
    /// Stable identity of this machine (generated once); a PC controller
    /// presents it as its device_id when pairing with another PC.
    pub self_id: String,
    /// Other PCs this machine's UI can control (PC controlling PC).
    pub remote_pcs: Vec<RemotePc>,
}

/// A remote PC the desktop UI can control, paired like a phone is.
#[derive(Clone, Serialize, Deserialize)]
pub struct RemotePc {
    pub id: String,
    pub name: String,
    pub host: String,
    pub port: u16,
    /// Secret issued by the remote PC after approval.
    pub secret: String,
    /// One-time pairing token copied from the remote PC's link, used until
    /// the secret above exists.
    #[serde(default)]
    pub token: String,
}

#[derive(Clone, Serialize, Deserialize, Default)]
pub struct Device {
    pub id: String,
    pub name: String,
    pub secret: String,
    pub paired_at: String,
    pub last_seen: String,
    /// True when the device is another PC's WinRelay (PC controlling PC).
    #[serde(default)]
    pub pc: bool,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Activity {
    pub start: String,
    pub end: String,
    pub device: String,
    pub window: String,
    pub stealth: bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            port: 47800,
            allow_internet: false,
            ddns_host: String::new(),
            pairing_token: random_token(24),
            devices: vec![],
            hidden_apps: vec![
                "KeePassXC.exe".into(),
                "KeePass.exe".into(),
                "1Password.exe".into(),
                "Bitwarden.exe".into(),
            ],
            idle_timeout_min: 15,
            lock_on_disconnect: false,
            stealth_default: false,
            hide_taskbar_in_stealth: true,
            fence_cursor: true,
            max_fps: 15,
            jpeg_quality: 85,
            virtual_monitor_match: "virtual;idd;parsec".into(),
            keep_awake: true,
            screens_off_on_start: false,
            log_days: 30,
            self_id: String::new(),
            remote_pcs: vec![],
        }
    }
}

pub fn random_token(n: usize) -> String {
    rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(n)
        .map(char::from)
        .collect()
}

pub fn now() -> String {
    chrono::Local::now().to_rfc3339()
}

use std::sync::OnceLock;
static DATA_DIR: OnceLock<PathBuf> = OnceLock::new();

/// Overrides the data directory (--config-dir), mainly for a second instance.
pub fn set_data_dir(dir: String) {
    let _ = DATA_DIR.set(PathBuf::from(dir));
}

pub fn data_dir() -> PathBuf {
    if let Some(d) = DATA_DIR.get() {
        let _ = fs::create_dir_all(d);
        return d.clone();
    }
    let dir = dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("WinRelay");
    let _ = fs::create_dir_all(&dir);
    dir
}

pub fn load() -> Config {
    match load_json_opt::<Config>("config.json") {
        Some(c) => c,
        None => {
            let c = Config::default();
            save(&c);
            c
        }
    }
}

pub fn save(c: &Config) {
    save_json("config.json", c);
}

pub fn load_json_opt<T: DeserializeOwned>(name: &str) -> Option<T> {
    let text = fs::read_to_string(data_dir().join(name)).ok()?;
    serde_json::from_str(&text).ok()
}

pub fn load_json<T: DeserializeOwned + Default>(name: &str) -> T {
    load_json_opt(name).unwrap_or_default()
}

pub fn save_json<T: Serialize>(name: &str, value: &T) {
    if let Ok(text) = serde_json::to_string_pretty(value) {
        let _ = fs::write(data_dir().join(name), text);
    }
}

/// Keep only entries newer than `days`.
pub fn prune_activity(list: &mut Vec<Activity>, days: u32) {
    if days == 0 {
        list.clear();
        return;
    }
    let cutoff = chrono::Local::now() - chrono::Duration::days(days as i64);
    list.retain(|a| {
        chrono::DateTime::parse_from_rfc3339(&a.start)
            .map(|t| t > cutoff)
            .unwrap_or(false)
    });
}
