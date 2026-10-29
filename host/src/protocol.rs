//! Phone <-> host protocol over one WebSocket.
//! Text frames carry JSON messages tagged by "t".
//! Binary frames carry pictures: [kind u8][window id u64 LE][width u32 LE][height u32 LE][JPEG bytes].

use serde::{Deserialize, Serialize};

pub const FRAME_VIDEO: u8 = 1;
pub const FRAME_THUMB: u8 = 2;
/// Sent internally (never on the wire) by the capture thread when the window disappears.
pub const FRAME_GONE: u8 = 0;
pub const HEADER_LEN: usize = 17;

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
    Hello {
        device_id: String,
        device_name: String,
        #[serde(default)]
        token: Option<String>,
        #[serde(default)]
        secret: Option<String>,
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
        /// capture frame rate, picture downscale (1.0 = full size), grayscale.
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
    },
    /// Live stream retune while a session is running. Any subset can be sent.
    Stream {
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
    },
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
    /// Wheel notches; positive scrolls up.
    Scroll { dy: i32 },
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
    Closed { reason: String },
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
