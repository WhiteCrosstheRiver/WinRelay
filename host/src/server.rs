use crate::capture::{self, CaptureOptions};
use crate::config::{self, Activity, Config, Device};
use crate::input::{self, Cmd};
use crate::protocol::*;
use crate::{browser, display, fs, net, power, session, winlist};
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use axum::extract::{ConnectInfo, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use futures_util::{SinkExt, StreamExt};
use parking_lot::Mutex;
use serde::Deserialize;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{mpsc, oneshot, Notify};

const UI_HTML: &str = include_str!("../ui/index.html");

pub struct ActiveInfo {
    pub device: String,
    pub title: String,
    pub stealth: bool,
    pub since: String,
}

pub struct Pending {
    pub id: String,
    pub name: String,
    pub reply: Option<oneshot::Sender<bool>>,
}

pub struct AppState {
    pub cfg: Mutex<Config>,
    pub active: Mutex<Option<ActiveInfo>>,
    /// Connected phone: device id + a handle to disconnect it.
    pub connected: Mutex<Option<(String, String, Arc<Notify>)>>,
    pub pending: Mutex<Vec<Pending>>,
    pub activity: Mutex<Vec<Activity>>,
    pub fails: Mutex<HashMap<IpAddr, (u32, Instant)>>,
    pub screens_off: Arc<AtomicBool>,
}

pub type Shared = Arc<AppState>;

impl AppState {
    pub fn new(cfg: Config) -> Shared {
        let mut activity: Vec<Activity> = config::load_json("activity.json");
        config::prune_activity(&mut activity, cfg.log_days);
        Arc::new(Self {
            cfg: Mutex::new(cfg),
            active: Mutex::new(None),
            connected: Mutex::new(None),
            pending: Mutex::new(Vec::new()),
            activity: Mutex::new(activity),
            fails: Mutex::new(HashMap::new()),
            screens_off: Arc::new(AtomicBool::new(false)),
        })
    }

    pub fn emergency(&self) {
        if let Some((_, _, kick)) = self.connected.lock().as_ref() {
            kick.notify_one();
        }
        session::restore_all();
    }

    fn blocked(&self, ip: IpAddr) -> bool {
        let fails = self.fails.lock();
        matches!(fails.get(&ip), Some((n, t)) if *n >= 5 && t.elapsed() < Duration::from_secs(3600))
    }

    fn fail(&self, ip: IpAddr) {
        let mut fails = self.fails.lock();
        let e = fails.entry(ip).or_insert((0, Instant::now()));
        if e.1.elapsed() > Duration::from_secs(3600) {
            *e = (0, Instant::now());
        }
        e.0 += 1;
        e.1 = Instant::now();
    }

    fn log_activity(&self, a: Activity) {
        let days = self.cfg.lock().log_days;
        let mut list = self.activity.lock();
        list.insert(0, a);
        config::prune_activity(&mut list, days);
        config::save_json("activity.json", &*list);
    }
}

pub fn router(state: Shared) -> Router {
    Router::new()
        .route("/ws", get(ws_handler))
        .route("/", get(|| async { axum::response::Redirect::to("/ui") }))
        .route("/ui", get(ui))
        .route("/api/status", get(status))
        .route("/api/qr.svg", get(qr_svg))
        .route("/api/approve", post(approve))
        .route("/api/end", post(end_session))
        .route("/api/restore", post(restore_windows))
        .route("/api/devices/remove", post(remove_device))
        .route("/api/devices/rename", post(rename_device))
        .route("/api/new-link", post(new_link))
        .route("/api/settings", post(save_settings))
        .route("/api/firewall", post(open_firewall))
        .with_state(state)
}

// ---------- Desktop UI (loopback only) ----------

fn local_only(addr: &SocketAddr) -> Result<(), StatusCode> {
    if addr.ip().to_canonical().is_loopback() {
        Ok(())
    } else {
        Err(StatusCode::FORBIDDEN)
    }
}

async fn ui(ConnectInfo(addr): ConnectInfo<SocketAddr>) -> Result<Html<&'static str>, StatusCode> {
    local_only(&addr)?;
    Ok(Html(UI_HTML))
}

fn current_link(cfg: &Config) -> String {
    let host = net::link_host(cfg, &net::addresses());
    net::pair_link(&host, cfg.port, &cfg.pairing_token, &net::host_name())
}

fn settings_view(cfg: &Config) -> Value {
    let mut v = serde_json::to_value(cfg).unwrap_or(Value::Null);
    if let Some(o) = v.as_object_mut() {
        o.remove("devices");
        o.remove("pairing_token");
    }
    v
}

async fn status(
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
) -> Result<Json<Value>, StatusCode> {
    local_only(&addr)?;
    let cfg = s.cfg.lock().clone();
    let active = s.active.lock().as_ref().map(|a| {
        json!({ "device": a.device, "title": a.title, "stealth": a.stealth, "since": a.since })
    });
    let connected = s.connected.lock().as_ref().map(|(_, name, _)| name.clone());
    let pending: Vec<Value> = s.pending.lock().iter().map(|p| json!({ "id": p.id, "name": p.name })).collect();
    let devices: Vec<Value> = cfg
        .devices
        .iter()
        .map(|d| json!({ "id": d.id, "name": d.name, "paired_at": d.paired_at, "last_seen": d.last_seen }))
        .collect();
    let virt = display::virtual_monitor(&cfg.virtual_monitor_match).map(|m| m.adapter);
    Ok(Json(json!({
        "host": net::host_name(),
        "port": cfg.port,
        "addresses": net::addresses(),
        "link": current_link(&cfg),
        "connected": connected,
        "active": active,
        "pending": pending,
        "devices": devices,
        "activity": *s.activity.lock(),
        "virtual_display": virt,
        "locked": power::is_locked(),
        "settings": settings_view(&cfg),
    })))
}

async fn qr_svg(State(s): State<Shared>, ConnectInfo(addr): ConnectInfo<SocketAddr>) -> Response {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN.into_response();
    }
    let link = current_link(&s.cfg.lock());
    match qrcode::QrCode::new(link.as_bytes()) {
        Ok(code) => {
            let svg = code
                .render::<qrcode::render::svg::Color>()
                .min_dimensions(232, 232)
                .quiet_zone(true)
                .dark_color(qrcode::render::svg::Color("#16202c"))
                .light_color(qrcode::render::svg::Color("#ffffff"))
                .build();
            ([(header::CONTENT_TYPE, "image/svg+xml"), (header::CACHE_CONTROL, "no-store")], svg).into_response()
        }
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}

#[derive(Deserialize)]
struct ApproveReq {
    id: String,
    allow: bool,
}

async fn approve(
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<ApproveReq>,
) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    let mut pending = s.pending.lock();
    if let Some(p) = pending.iter_mut().find(|p| p.id == req.id) {
        if let Some(tx) = p.reply.take() {
            let _ = tx.send(req.allow);
        }
    }
    pending.retain(|p| p.reply.is_some());
    StatusCode::OK
}

async fn end_session(State(s): State<Shared>, ConnectInfo(addr): ConnectInfo<SocketAddr>) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    if let Some((_, _, kick)) = s.connected.lock().as_ref() {
        kick.notify_one();
    }
    StatusCode::OK
}

async fn restore_windows(State(s): State<Shared>, ConnectInfo(addr): ConnectInfo<SocketAddr>) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    s.emergency();
    StatusCode::OK
}

#[derive(Deserialize)]
struct DeviceReq {
    id: String,
    #[serde(default)]
    name: String,
}

async fn remove_device(
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<DeviceReq>,
) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    {
        let mut cfg = s.cfg.lock();
        cfg.devices.retain(|d| d.id != req.id);
        config::save(&cfg);
    }
    if let Some((id, _, kick)) = s.connected.lock().as_ref() {
        if *id == req.id {
            kick.notify_one();
        }
    }
    StatusCode::OK
}

async fn rename_device(
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<DeviceReq>,
) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    let mut cfg = s.cfg.lock();
    if let Some(d) = cfg.devices.iter_mut().find(|d| d.id == req.id) {
        d.name = req.name.trim().chars().take(40).collect();
    }
    config::save(&cfg);
    StatusCode::OK
}

async fn new_link(State(s): State<Shared>, ConnectInfo(addr): ConnectInfo<SocketAddr>) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    let mut cfg = s.cfg.lock();
    cfg.pairing_token = config::random_token(24);
    config::save(&cfg);
    StatusCode::OK
}

/// Merges the posted fields into the config. Devices and the pairing token
/// can't be changed this way.
async fn save_settings(
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(incoming): Json<Value>,
) -> Result<Json<Value>, (StatusCode, String)> {
    local_only(&addr).map_err(|c| (c, String::new()))?;
    let mut cfg = s.cfg.lock();
    let mut v = serde_json::to_value(&*cfg).map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    if let (Some(dst), Some(src)) = (v.as_object_mut(), incoming.as_object()) {
        for (k, val) in src {
            if k != "devices" && k != "pairing_token" && dst.contains_key(k) {
                dst.insert(k.clone(), val.clone());
            }
        }
    }
    let next: Config = serde_json::from_value(v).map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?;
    let restart = next.port != cfg.port;
    *cfg = next;
    config::save(&cfg);
    Ok(Json(json!({ "saved": true, "restart_needed": restart })))
}

/// Adds an inbound firewall rule. Windows shows its own admin prompt.
async fn open_firewall(State(s): State<Shared>, ConnectInfo(addr): ConnectInfo<SocketAddr>) -> StatusCode {
    if local_only(&addr).is_err() {
        return StatusCode::FORBIDDEN;
    }
    let port = s.cfg.lock().port;
    let args = format!(
        "advfirewall firewall add rule name=\"WinRelay\" dir=in action=allow protocol=TCP localport={port}"
    );
    let ps = format!("Start-Process netsh -Verb RunAs -ArgumentList '{args}'");
    match std::process::Command::new("powershell").args(["-NoProfile", "-Command", &ps]).spawn() {
        Ok(_) => StatusCode::OK,
        Err(_) => StatusCode::INTERNAL_SERVER_ERROR,
    }
}

// ---------- Phone connection ----------

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(s): State<Shared>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
) -> Response {
    let ip = addr.ip().to_canonical();
    let allow_internet = s.cfg.lock().allow_internet;
    if !allow_internet && !net::is_local(ip) {
        return StatusCode::FORBIDDEN.into_response();
    }
    if s.blocked(ip) {
        return StatusCode::TOO_MANY_REQUESTS.into_response();
    }
    ws.max_message_size(1 << 20)
        .on_upgrade(move |sock| async move { client(sock, s, ip).await })
}

async fn tx(out: &mpsc::Sender<Message>, m: HostMsg) {
    if let Ok(text) = serde_json::to_string(&m) {
        let _ = out.send(Message::Text(text)).await;
    }
}

/// Checks the hello. Known device + secret: in. Pairing token: wait for a click
/// on Approve in the desktop app, then issue this phone its own secret.
async fn authenticate(s: &Shared, out: &mpsc::Sender<Message>, hello: ClientMsg) -> Option<(String, String)> {
    let ClientMsg::Hello { device_id, device_name, token, secret } = hello else {
        return None;
    };
    let name: String = device_name.trim().chars().take(40).collect();

    if let Some(secret) = secret {
        let mut cfg = s.cfg.lock();
        let found = cfg.devices.iter_mut().find(|d| d.id == device_id && d.secret == secret)?;
        found.last_seen = config::now();
        let name = found.name.clone();
        config::save(&cfg);
        return Some((device_id, name));
    }

    let token = token?;
    if token != s.cfg.lock().pairing_token {
        return None;
    }
    let (reply_tx, reply_rx) = oneshot::channel();
    s.pending.lock().push(Pending { id: device_id.clone(), name: name.clone(), reply: Some(reply_tx) });
    tx(out, HostMsg::Pending).await;

    let allowed = matches!(tokio::time::timeout(Duration::from_secs(120), reply_rx).await, Ok(Ok(true)));
    s.pending.lock().retain(|p| p.id != device_id);
    if !allowed {
        return None;
    }

    let secret = config::random_token(40);
    {
        let mut cfg = s.cfg.lock();
        cfg.devices.retain(|d| d.id != device_id);
        cfg.devices.push(Device {
            id: device_id.clone(),
            name: name.clone(),
            secret: secret.clone(),
            paired_at: config::now(),
            last_seen: config::now(),
        });
        // A pairing link works once.
        cfg.pairing_token = config::random_token(24);
        config::save(&cfg);
    }
    tx(out, HostMsg::Approved { secret }).await;
    Some((device_id, name))
}

/// Reads the browser session's current page in the background and sends it.
fn push_browser_url(out: &mpsc::Sender<Message>, id: u64) {
    let out = out.clone();
    tokio::spawn(async move {
        let url = tokio::task::spawn_blocking(move || browser::current_url(winlist::hwnd(id)))
            .await
            .ok()
            .flatten();
        if let Some(url) = url {
            if let Ok(text) = serde_json::to_string(&HostMsg::Url { url }) {
                let _ = out.send(Message::Text(text)).await;
            }
        }
    });
}

/// In-flight upload: the partially written file plus how much has arrived.
struct UploadSink {
    file: std::fs::File,
    size: u64,
    received: u64,
}

fn next_fs_id() -> u64 {
    use std::sync::atomic::{AtomicU64, Ordering};
    static NEXT: AtomicU64 = AtomicU64::new(1);
    NEXT.fetch_add(1, Ordering::Relaxed)
}

async fn report_fs(out: &mpsc::Sender<Message>, id: u64, r: Result<anyhow::Result<()>, tokio::task::JoinError>) {
    let (ok, error) = match r {
        Ok(Ok(())) => (true, None),
        Ok(Err(e)) => (false, Some(e.to_string())),
        Err(e) => (false, Some(e.to_string())),
    };
    tx(out, HostMsg::FsDone { id, ok, error }).await;
}

struct Live {
    session: session::Session,
    stop: Arc<AtomicBool>,
    /// Shared with the capture thread; the phone retunes fps/scale/gray here.
    params: Arc<capture::CaptureParams>,
    capture: Option<std::thread::JoinHandle<()>>,
    activity: Activity,
}

fn end_live(s: &Shared, live: Live, input_tx: &std::sync::mpsc::Sender<Cmd>) {
    live.stop.store(true, Ordering::Relaxed);
    if let Some(j) = live.capture {
        let _ = j.join();
    }
    let _ = input_tx.send(Cmd::Target(None));
    s.screens_off.store(false, Ordering::Relaxed);
    session::end(live.session);
    *s.active.lock() = None;
    let mut a = live.activity;
    a.end = config::now();
    s.log_activity(a);
}

async fn client(sock: WebSocket, s: Shared, ip: IpAddr) {
    let (mut sink, mut stream) = sock.split();
    let (out, mut out_rx) = mpsc::channel::<Message>(16);
    let writer = tokio::spawn(async move {
        while let Some(m) = out_rx.recv().await {
            if sink.send(m).await.is_err() {
                break;
            }
        }
    });

    // ---- hello / pairing ----
    let first = tokio::time::timeout(Duration::from_secs(10), stream.next()).await;
    let hello = match first {
        Ok(Some(Ok(Message::Text(t)))) => serde_json::from_str::<ClientMsg>(&t).ok(),
        _ => None,
    };
    let auth = match hello {
        Some(h @ ClientMsg::Hello { .. }) => authenticate(&s, &out, h).await,
        _ => None,
    };
    let Some((device_id, device_name)) = auth else {
        s.fail(ip);
        tx(&out, HostMsg::Denied { reason: "This phone isn't approved on the PC. Pair it again from WinRelay on the PC.".into() }).await;
        drop(out);
        let _ = writer.await;
        return;
    };

    // One phone at a time: a new connection from any phone replaces the old one.
    let kick = Arc::new(Notify::new());
    if let Some((_, _, old)) = s.connected.lock().replace((device_id.clone(), device_name.clone(), kick.clone())) {
        old.notify_one();
    }
    tx(&out, HostMsg::Welcome { host: net::host_name() }).await;

    let input_tx = input::spawn_worker(s.screens_off.clone());
    let (frame_tx, mut frame_rx) = mpsc::channel::<Vec<u8>>(2);
    let mut live: Option<Live> = None;
    let mut last_msg = Instant::now();
    let mut was_locked = false;
    let mut tick = tokio::time::interval(Duration::from_secs(1));
    // Active uploads: declared with FsUploadBegin, fed by kind=4 binary
    // frames, finished by FsUploadEnd. Dropped (and files closed) on any
    // disconnect.
    let mut uploads: HashMap<u64, UploadSink> = HashMap::new();

    loop {
        tokio::select! {
            _ = kick.notified() => {
                tx(&out, HostMsg::Closed { reason: "Disconnected from the PC.".into() }).await;
                break;
            }
            frame = frame_rx.recv() => {
                match frame {
                    Some(b) if b.len() == 1 && b[0] == FRAME_GONE => {
                        if let Some(l) = live.take() { end_live(&s, l, &input_tx); }
                        tx(&out, HostMsg::Closed { reason: "The window was closed on the PC.".into() }).await;
                    }
                    Some(b) => { let _ = out.send(Message::Binary(b)).await; }
                    None => {}
                }
            }
            _ = tick.tick() => {
                session::refence();
                let idle_min = s.cfg.lock().idle_timeout_min;
                if idle_min > 0 && last_msg.elapsed() > Duration::from_secs(idle_min as u64 * 60) {
                    tx(&out, HostMsg::Closed { reason: "Disconnected after being idle.".into() }).await;
                    break;
                }
                if live.is_some() {
                    let locked = power::is_locked();
                    if locked != was_locked {
                        was_locked = locked;
                        tx(&out, HostMsg::Locked { locked }).await;
                    }
                }
            }
            msg = stream.next() => {
                let Some(Ok(msg)) = msg else { break };
                let text = match msg {
                    Message::Text(t) => t,
                    Message::Binary(b) => {
                        // Upload chunks: [kind=4][id][offset][total][data].
                        if b.len() > FS_HEADER_LEN && b[0] == FRAME_FS_WRITE {
                            let (_, id, offset, _total, data) = fs_frame_parts(&b);
                            if let Some(sink) = uploads.get_mut(&id) {
                                use std::io::{Seek, SeekFrom, Write};
                                let r = (|| -> std::io::Result<()> {
                                    sink.file.seek(SeekFrom::Start(offset))?;
                                    sink.file.write_all(data)?;
                                    sink.received = sink.received.max(offset + data.len() as u64);
                                    Ok(())
                                })();
                                if let Err(e) = r {
                                    uploads.remove(&id);
                                    tx(&out, HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }).await;
                                }
                            }
                        }
                        continue;
                    }
                    Message::Close(_) => break,
                    _ => continue,
                };
                let Ok(msg) = serde_json::from_str::<ClientMsg>(&text) else { continue };
                last_msg = Instant::now();
                match msg {
                    ClientMsg::Ping => tx(&out, HostMsg::Pong).await,
                    ClientMsg::List => {
                        let hidden = s.cfg.lock().hidden_apps.clone();
                        let items = tokio::task::spawn_blocking(move || winlist::list_windows(&hidden)).await.unwrap_or_default();
                        tx(&out, HostMsg::Windows { items }).await;
                    }
                    ClientMsg::Thumb { id } => {
                        let hidden = s.cfg.lock().hidden_apps.clone();
                        let out2 = out.clone();
                        tokio::spawn(async move {
                            let pic = tokio::task::spawn_blocking(move || {
                                if !winlist::is_listable(id, &hidden) { return None; }
                                let f = capture::grab(winlist::hwnd(id))?;
                                let small = capture::downscale(&f, 360);
                                let jpg = capture::encode(&small, 70).ok()?;
                                Some(binary(FRAME_THUMB, id, small.w, small.h, &jpg))
                            }).await.ok().flatten();
                            if let Some(b) = pic { let _ = out2.send(Message::Binary(b)).await; }
                        });
                    }
                    ClientMsg::Open { id, stealth, viewport, scale, fps, pic_scale, gray } => {
                        if let Some(l) = live.take() { end_live(&s, l, &input_tx); }
                        let cfg = s.cfg.lock().clone();
                        if !winlist::is_listable(id, &cfg.hidden_apps) {
                            tx(&out, HostMsg::Error { msg: "That window isn't available any more. Refresh the list.".into() }).await;
                            continue;
                        }
                        let opts = session::Options {
                            stealth,
                            hide_taskbar: cfg.hide_taskbar_in_stealth,
                            fence_cursor: cfg.fence_cursor,
                            matchers: &cfg.virtual_monitor_match,
                        };
                        match session::begin(id, viewport, scale.clamp(0.5, 3.0), &opts) {
                            Ok(sess) => {
                                let stop = Arc::new(AtomicBool::new(false));
                                let params = capture::CaptureParams::new(cfg.max_fps, cfg.jpeg_quality);
                                params.set(fps, pic_scale, gray);
                                let cap = capture::spawn(
                                    id,
                                    CaptureOptions { params: params.clone(), keep_awake: cfg.keep_awake },
                                    frame_tx.clone(),
                                    stop.clone(),
                                );
                                let _ = input_tx.send(Cmd::Target(Some(id)));
                                if cfg.screens_off_on_start {
                                    s.screens_off.store(true, Ordering::Relaxed);
                                    power::screens_off();
                                }
                                *s.active.lock() = Some(ActiveInfo {
                                    device: device_name.clone(),
                                    title: sess.title.clone(),
                                    stealth,
                                    since: config::now(),
                                });
                                let activity = Activity {
                                    start: config::now(),
                                    end: String::new(),
                                    device: device_name.clone(),
                                    window: sess.title.clone(),
                                    stealth,
                                };
                                tx(&out, HostMsg::Opened { id, title: sess.title.clone(), stealth }).await;
                                was_locked = false;
                                live = Some(Live { session: sess, stop, params, capture: Some(cap), activity });
                                // A browser session also hands the phone the
                                // page being shown, for the phone-side web view.
                                if winlist::exe_of(winlist::hwnd(id))
                                    .map(|e| browser::is_browser_exe(&e))
                                    .unwrap_or(false)
                                {
                                    push_browser_url(&out, id);
                                }
                            }
                            Err(e) => tx(&out, HostMsg::Error { msg: e.to_string() }).await,
                        }
                    }
                    ClientMsg::Stream { fps, pic_scale, gray } => {
                        if let Some(l) = &live {
                            l.params.set(fps, pic_scale, gray);
                        }
                    }
                    ClientMsg::Navigate { url } => {
                        if let Some(l) = &live {
                            // Only real web URLs; the address bar is a text
                            // field, so anything else would be typed into it.
                            if (url.starts_with("http://") || url.starts_with("https://")) && url.len() <= 2048 {
                                let id = l.session.id;
                                let u = url;
                                tokio::task::spawn_blocking(move || browser::navigate(winlist::hwnd(id), &u)).await.ok();
                            } else {
                                tx(&out, HostMsg::Error { msg: "Only http(s) URLs can be sent to the browser.".into() }).await;
                            }
                        }
                    }
                    ClientMsg::GetUrl => {
                        if let Some(l) = &live {
                            push_browser_url(&out, l.session.id);
                        }
                    }
                    ClientMsg::FsList { path } => {
                        let p = path.clone();
                        let items = tokio::task::spawn_blocking(move || fs::list(&p)).await.unwrap_or_else(|_| Ok(vec![]));
                        match items {
                            Ok(items) => tx(&out, HostMsg::FsEntries { path, items }).await,
                            Err(e) => tx(&out, HostMsg::FsDone { id: 0, ok: false, error: Some(e.to_string()) }).await,
                        }
                    }
                    ClientMsg::FsMkdir { path } => {
                        let id = next_fs_id();
                        let p = path.clone();
                        let r = tokio::task::spawn_blocking(move || {
                            fs::writable(&p)?;
                            fs::mkdir(&p)
                        })
                        .await;
                        report_fs(&out, id, r).await;
                    }
                    ClientMsg::FsDelete { path } => {
                        let id = next_fs_id();
                        let p = path.clone();
                        let r = tokio::task::spawn_blocking(move || fs::delete_to_trash(&p)).await;
                        report_fs(&out, id, r).await;
                    }
                    ClientMsg::FsDownload { id, path } => {
                        let out2 = out.clone();
                        tokio::spawn(async move {
                            let total = match tokio::task::spawn_blocking({
                                let path = path.clone();
                                move || fs::total_size(&path)
                            })
                            .await
                            {
                                Ok(Ok(t)) => t,
                                Ok(Err(e)) => {
                                    if let Ok(t) = serde_json::to_string(&HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }) {
                                        let _ = out2.send(Message::Text(t)).await;
                                    }
                                    return;
                                }
                                Err(e) => {
                                    if let Ok(t) = serde_json::to_string(&HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }) {
                                        let _ = out2.send(Message::Text(t)).await;
                                    }
                                    return;
                                }
                            };
                            if let Ok(t) = serde_json::to_string(&HostMsg::FsMeta { id, size: total }) {
                                let _ = out2.send(Message::Text(t)).await;
                            }
                            let _ = tokio::task::spawn_blocking(move || {
                                let mut offset = 0u64;
                                loop {
                                    let (chunk, done) = match fs::read_chunk(&path, offset, fs::CHUNK_SIZE) {
                                        Ok(r) => r,
                                        Err(e) => {
                                            if let Ok(t) = serde_json::to_string(&HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }) {
                                                let _ = out2.blocking_send(Message::Text(t));
                                            }
                                            break;
                                        }
                                    };
                                    if out2.blocking_send(Message::Binary(fs_frame(FRAME_FS_READ, id, offset, total, &chunk))).is_err() {
                                        break;
                                    }
                                    offset += chunk.len() as u64;
                                    if done {
                                        if let Ok(t) = serde_json::to_string(&HostMsg::FsDone { id, ok: true, error: None }) {
                                            let _ = out2.blocking_send(Message::Text(t));
                                        }
                                        break;
                                    }
                                }
                            })
                            .await;
                        });
                    }
                    ClientMsg::FsUploadBegin { id, path, size } => {
                        let p = path.clone();
                        let sink = tokio::task::spawn_blocking(move || -> anyhow::Result<UploadSink> {
                            fs::writable(&p)?;
                            Ok(UploadSink { file: std::fs::File::create(&p)?, size, received: 0 })
                        })
                        .await;
                        match sink {
                            Ok(Ok(sink)) => {
                                uploads.insert(id, sink);
                                tx(&out, HostMsg::FsUploadReady { id }).await;
                            }
                            Ok(Err(e)) => {
                                tx(&out, HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }).await;
                            }
                            Err(e) => {
                                tx(&out, HostMsg::FsDone { id, ok: false, error: Some(e.to_string()) }).await;
                            }
                        }
                    }
                    ClientMsg::FsUploadEnd { id } => {
                        let sink = uploads.remove(&id);
                        match sink {
                            Some(sink) if sink.received >= sink.size => {
                                tx(&out, HostMsg::FsDone { id, ok: true, error: None }).await;
                            }
                            Some(sink) => {
                                tx(&out, HostMsg::FsDone {
                                    id,
                                    ok: false,
                                    error: Some(format!("Incomplete upload: {} of {} bytes.", sink.received, sink.size)),
                                })
                                .await;
                            }
                            None => {
                                tx(&out, HostMsg::FsDone { id, ok: false, error: Some("Unknown upload.".into()) }).await;
                            }
                        }
                    }
                    ClientMsg::Viewport { viewport } => {
                        if let Some(l) = &live {
                            let m = s.cfg.lock().virtual_monitor_match.clone();
                            session::refit(&l.session, viewport, &m);
                        }
                    }
                    ClientMsg::Close => {
                        if let Some(l) = live.take() { end_live(&s, l, &input_tx); }
                        tx(&out, HostMsg::Closed { reason: "closed".into() }).await;
                    }
                    ClientMsg::Text { s: text } => { let _ = input_tx.send(Cmd::Text(text)); }
                    ClientMsg::Key { k } => { let _ = input_tx.send(Cmd::Key(k)); }
                    ClientMsg::Tap { x, y, kind } => { let _ = input_tx.send(Cmd::Tap { x, y, kind }); }
                    ClientMsg::Scroll { dy } => { let _ = input_tx.send(Cmd::Scroll(dy)); }
                    ClientMsg::Hello { .. } => {}
                }
            }
        }
    }

    // ---- teardown ----
    if let Some(l) = live.take() {
        end_live(&s, l, &input_tx);
    }
    {
        let mut c = s.connected.lock();
        if matches!(c.as_ref(), Some((_, _, k)) if Arc::ptr_eq(k, &kick)) {
            *c = None;
        }
    }
    if s.cfg.lock().lock_on_disconnect {
        power::lock();
    }
    drop(out);
    writer.abort();
}
