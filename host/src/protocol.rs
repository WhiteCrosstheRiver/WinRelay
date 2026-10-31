//! Phone <-> host protocol over one WebSocket.
//! Text frames carry JSON messages tagged by "t".
//! Binary frames carry pictures: [kind u8][window id u64 LE][width u32 LE][height u32 LE][JPEG bytes].

use serde::{Deserialize, Serialize};

pub const FRAME_VIDEO: u8 = 1;
pub const FRAME_THUMB: u8 = 2;
/// File-transfer binary frames: [kind u8][id u64 LE][offset u64 LE][total u64 LE][data].
pub const FRAME_FS_READ: u8 = 3; // PC -> phone (download chunk)
pub const FRAME_FS_WRITE: u8 = 4; // phone -> PC (upload chunk)
/// Sent internally (never on the wire) by the capture thread when the window disappears.
pub const FRAME_GONE: u8 = 0;
pub const HEADER_LEN: usize = 17;
pub const FS_HEADER_LEN: usize = 25;

#[derive(Deserialize, Clone, Copy, Debug)]
pub struct Viewport {
    /// Phone viewport in logical pixels.
    pub w: f32,
    pub h: f32,
    pub dpr: f32,
}

#[derive(Deserialize, Default, Clone, Copy, Debug)]
#[serde(rename_all = "snake_case")]
pub enum TapKind {
    #[default]
    Left,
    Right,
    Double,
}

#[derive(Deserialize, Debug)]
#[serde(tag = "t", rename_all = "snake_case")]
pub enum ClientMsg {
    /// First message on every connection. `token` while pairing, `secret` afterwards.
    /// `pc_controller` marks a connection from another PC's WinRelay UI (PC
    /// controlling PC); the host enforces single-control rules for those.
    Hello {
        device_id: String,
        device_name: String,
        #[serde(default)]
        token: Option<String>,
        #[serde(default)]
        secret: Option<String>,
        #[serde(default)]
        pc_controller: bool,
    },
    List,
    Thumb { id: u64 },
    Open {
        id: u64,
        stealth: bool,
        viewport: Viewport,
        /// PC window logical size = phone logical size x scale.
        #[serde(default = "default_scale")]
        scale: f32,
        /// Stream overrides, applied for this session (phone saves bandwidth):
        /// capture frame rate, picture downscale (1.0 = full size), grayscale,
        /// pure black-and-white.
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
        #[serde(default)]
        bw: Option<bool>,
    },
    /// Live stream retune while a session is running. Any subset can be sent.
    Stream {
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
        #[serde(default)]
        bw: Option<bool>,
    },
    /// App launcher: search Start-Menu apps, launch or close one.
    AppsSearch { q: String },
    AppLaunch { path: String },
    AppClose { name: String },
    /// Clipboard relay (phone bridges two PCs): read this PC's clipboard.
    ClipGet,
    /// Write this PC's clipboard so a following Ctrl+V pastes the text.
    ClipSet { s: String },
    /// Phone's web view navigated: point the browser at the same page.
    Navigate { url: String },
    /// Phone asks for the browser's current URL again (HostMsg::Url).
    GetUrl,
    /// File browsing: "" lists the drives ("This PC").
    FsList { path: String },
    FsMkdir { path: String },
    FsDelete { path: String },
    /// PC streams the file back as kind=3 binary chunks, then FsDone.
    FsDownload { id: u64, path: String },
    /// Phone declares an upload, waits for FsUploadReady, sends kind=4 binary
    /// chunks ([id][offset][total][data]), then FsUploadEnd.
    FsUploadBegin { id: u64, path: String, size: u64 },
    FsUploadEnd { id: u64 },
    Viewport { viewport: Viewport },
    Close,
    /// Characters as typed. "\n" is sent as the Return key.
    Text { s: String },
    /// Named key: enter, shift_enter, ctrl_enter, backspace, esc, tab, shift_tab,
    /// ctrl_c, ctrl_v, ctrl_z, up, down, left, right, home, end, pgup, pgdn, delete.
    Key { k: String },
    /// Normalised position inside the streamed picture (0..1).
    Tap {
        x: f32,
        y: f32,
        #[serde(default)]
        kind: TapKind,
    },
    /// Wheel notches; positive scrolls up. The touch point (0..1 within the
    /// picture) makes the wheel land where the finger is — scrolling works
    /// even when the window centre is an input box or a dead area.
    Scroll {
        dy: i32,
        #[serde(default)]
        x: Option<f32>,
        #[serde(default)]
        y: Option<f32>,
    },
    Ping,
}

fn default_scale() -> f32 {
    1.25
}

#[derive(Serialize, Clone, Debug)]
pub struct WinInfo {
    pub id: u64,
    pub title: String,
    pub app: String,
    pub exe: String,
}

#[derive(Serialize, Debug)]
#[serde(tag = "t", rename_all = "snake_case")]
pub enum HostMsg {
    Welcome { host: String },
    Pending,
    Approved { secret: String },
    Denied { reason: String },
    Windows { items: Vec<WinInfo> },
    Opened { id: u64, title: String, stealth: bool },
    /// The session window is a browser; this is the page it is showing now.
    Url { url: String },
    Closed { reason: String },
    // ---- file browsing ----
    FsEntries { path: String, items: Vec<crate::fs::FsItem>, #[serde(default)] desktop: String },
    FsDone { id: u64, ok: bool, error: Option<String> },
    FsMeta { id: u64, size: u64 },
    FsUploadReady { id: u64 },
    /// Reply to ClipGet; empty string when the clipboard holds no text.
    ClipText { s: String },
    /// ClipSet (and other clipboard writes) completed.
    ClipOk,
    /// Reply to AppsSearch; running apps come first.
    Apps { q: String, items: Vec<crate::apps::AppInfo> },
    /// AppLaunch / AppClose outcome.
    AppResult { ok: bool, error: Option<String> },
    Locked { locked: bool },
    Error { msg: String },
    Pong,
}

pub fn binary(kind: u8, id: u64, w: u32, h: u32, jpeg: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(HEADER_LEN + jpeg.len());
    out.push(kind);
    out.extend_from_slice(&id.to_le_bytes());
    out.extend_from_slice(&w.to_le_bytes());
    out.extend_from_slice(&h.to_le_bytes());
    out.extend_from_slice(jpeg);
    out
}

pub fn fs_frame(kind: u8, id: u64, offset: u64, total: u64, data: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(FS_HEADER_LEN + data.len());
    out.push(kind);
    out.extend_from_slice(&id.to_le_bytes());
    out.extend_from_slice(&offset.to_le_bytes());
    out.extend_from_slice(&total.to_le_bytes());
    out.extend_from_slice(data);
    out
}

/// Parses an incoming file-transfer frame (already known to be long enough).
pub fn fs_frame_parts(b: &[u8]) -> (u8, u64, u64, u64, &[u8]) {
    let id = u64::from_le_bytes(b[1..9].try_into().unwrap());
    let offset = u64::from_le_bytes(b[9..17].try_into().unwrap());
    let total = u64::from_le_bytes(b[17..25].try_into().unwrap());
    (b[0], id, offset, total, &b[25..])
}
