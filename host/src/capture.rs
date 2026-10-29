//! Captures one window. MVP uses PrintWindow(PW_RENDERFULLCONTENT), which renders
//! the window even when it is covered or sits on the virtual monitor.
//! Upgrade path: Windows Graphics Capture + hardware H.264 (see README).

use crate::{power, protocol};
use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use windows::Win32::Foundation::{HANDLE, HWND, RECT};
use windows::Win32::Graphics::Dwm::{DwmGetWindowAttribute, DWMWA_EXTENDED_FRAME_BOUNDS};
use windows::Win32::Graphics::Gdi::{
    CreateCompatibleDC, CreateDIBSection, DeleteDC, DeleteObject, GetDC, ReleaseDC, SelectObject, BITMAPINFO,
    BITMAPINFOHEADER, BI_RGB, DIB_RGB_COLORS,
};
use windows::Win32::Storage::Xps::{PrintWindow, PRINT_WINDOW_FLAGS};
use windows::Win32::UI::WindowsAndMessaging::{GetWindowRect, IsWindow};

const PW_RENDERFULLCONTENT: u32 = 0x2;

pub struct Frame {
    pub w: u32,
    pub h: u32,
    /// Top-down BGRA rows.
    pub bgra: Vec<u8>,
}

/// The part of the window you can actually see (Windows 10/11 windows have
/// invisible resize borders that GetWindowRect includes).
pub fn visible_rect(h: HWND) -> RECT {
    unsafe {
        let mut r = RECT::default();
        let ok = DwmGetWindowAttribute(
            h,
            DWMWA_EXTENDED_FRAME_BOUNDS,
            &mut r as *mut RECT as *mut core::ffi::c_void,
            std::mem::size_of::<RECT>() as u32,
        );
        if ok.is_err() {
            let _ = GetWindowRect(h, &mut r);
        }
        r
    }
}

pub fn grab(h: HWND) -> Option<Frame> {
    unsafe {
        let mut wr = RECT::default();
        GetWindowRect(h, &mut wr).ok()?;
        let ww = wr.right - wr.left;
        let wh = wr.bottom - wr.top;
        if ww <= 0 || wh <= 0 {
            return None;
        }
        let vr = visible_rect(h);

        let screen = GetDC(HWND::default());
        let mem = CreateCompatibleDC(screen);
        let mut bmi = BITMAPINFO::default();
        bmi.bmiHeader = BITMAPINFOHEADER {
            biSize: std::mem::size_of::<BITMAPINFOHEADER>() as u32,
            biWidth: ww,
            biHeight: -wh, // negative = top-down rows
            biPlanes: 1,
            biBitCount: 32,
            biCompression: BI_RGB.0,
            ..Default::default()
        };
        let mut bits: *mut core::ffi::c_void = std::ptr::null_mut();
        let bmp = match CreateDIBSection(screen, &bmi, DIB_RGB_COLORS, &mut bits, HANDLE::default(), 0) {
            Ok(b) => b,
            Err(_) => {
                let _ = DeleteDC(mem);
                ReleaseDC(HWND::default(), screen);
                return None;
            }
        };
        let old = SelectObject(mem, bmp);
        let printed = PrintWindow(h, mem, PRINT_WINDOW_FLAGS(PW_RENDERFULLCONTENT)).as_bool();

        // Crop the invisible borders away.
        let ox = (vr.left - wr.left).clamp(0, ww);
        let oy = (vr.top - wr.top).clamp(0, wh);
        let cw = (vr.right - vr.left).min(ww - ox);
        let ch = (vr.bottom - vr.top).min(wh - oy);

        let mut frame = None;
        if printed && cw > 0 && ch > 0 && !bits.is_null() {
            let src = std::slice::from_raw_parts(bits as *const u8, (ww * wh * 4) as usize);
            let mut buf = Vec::with_capacity((cw * ch * 4) as usize);
            for y in 0..ch {
                let start = (((y + oy) * ww + ox) * 4) as usize;
                buf.extend_from_slice(&src[start..start + (cw * 4) as usize]);
            }
            frame = Some(Frame { w: cw as u32, h: ch as u32, bgra: buf });
        }

        SelectObject(mem, old);
        let _ = DeleteObject(bmp);
        let _ = DeleteDC(mem);
        ReleaseDC(HWND::default(), screen);
        frame
    }
}

/// Box-filter downscale so the frame is at most `max_w` wide (used for thumbnails).
pub fn downscale(f: &Frame, max_w: u32) -> Frame {
    if f.w <= max_w {
        return Frame { w: f.w, h: f.h, bgra: f.bgra.clone() };
    }
    downscale_to_width(f, max_w)
}

/// Area-average downscale to an exact target width (any fraction, not just
/// integer steps), so the phone can pick 75% or 50% of the picture.
pub fn downscale_to_width(f: &Frame, target_w: u32) -> Frame {
    if target_w == 0 || f.w <= target_w {
        return Frame { w: f.w, h: f.h, bgra: f.bgra.clone() };
    }
    let nw = target_w.max(1) as usize;
    let nh = (((f.h as u64) * nw as u64) / f.w as u64).max(1) as usize;
    let (w, h) = (f.w as usize, f.h as usize);
    let mut out = vec![0u8; nw * nh * 4];
    for oy in 0..nh {
        let sy0 = oy * h / nh;
        let sy1 = ((oy + 1) * h / nh).max(sy0 + 1);
        for ox in 0..nw {
            let sx0 = ox * w / nw;
            let sx1 = ((ox + 1) * w / nw).max(sx0 + 1);
            let mut acc = [0u64; 4];
            for sy in sy0..sy1 {
                let row = sy * w * 4;
                for sx in sx0..sx1 {
                    let i = row + sx * 4;
                    for c in 0..4 {
                        acc[c] += f.bgra[i + c] as u64;
                    }
                }
            }
            let n = ((sy1 - sy0) * (sx1 - sx0)) as u64;
            let o = (oy * nw + ox) * 4;
            for c in 0..4 {
                out[o + c] = (acc[c] / n) as u8;
            }
        }
    }
    Frame { w: nw as u32, h: nh as u32, bgra: out }
}

/// BT.601 luma in place; the alpha byte is left untouched.
pub fn to_gray(bgra: &mut [u8]) {
    for px in bgra.chunks_exact_mut(4) {
        let l = (0.299 * px[2] as f32 + 0.587 * px[1] as f32 + 0.114 * px[0] as f32) as u8;
        px[0] = l;
        px[1] = l;
        px[2] = l;
    }
}

/// Stream settings the phone can retune at any time. Shared with the capture
/// thread so changes apply from the next frame without a restart.
pub struct CaptureParams {
    pub fps: AtomicU32,
    pub quality: AtomicU8,
    /// Picture width as permille of the window's own width (1000 = full).
    pub scale_permil: AtomicU32,
    pub gray: AtomicBool,
}

impl CaptureParams {
    pub fn new(fps: u32, quality: u8) -> Arc<Self> {
        Arc::new(Self {
            fps: AtomicU32::new(fps.clamp(1, 60)),
            quality: AtomicU8::new(quality),
            scale_permil: AtomicU32::new(1000),
            gray: AtomicBool::new(false),
        })
    }

    pub fn set(&self, fps: Option<u32>, pic_scale: Option<f32>, gray: Option<bool>) {
        if let Some(f) = fps {
            self.fps.store(f.clamp(1, 60), Ordering::Relaxed);
        }
        if let Some(s) = pic_scale {
            self.scale_permil.store((s.clamp(0.05, 1.0) * 1000.0) as u32, Ordering::Relaxed);
        }
        if let Some(g) = gray {
            self.gray.store(g, Ordering::Relaxed);
        }
    }
}

/// JPEG with 4:4:4 chroma, which keeps coloured text crisp.
pub fn encode(f: &Frame, quality: u8) -> anyhow::Result<Vec<u8>> {
    use jpeg_encoder::{ColorType, Encoder, SamplingFactor};
    let mut out = Vec::new();
    let mut enc = Encoder::new(&mut out, quality.clamp(30, 95));
    enc.set_sampling_factor(SamplingFactor::R_4_4_4);
    enc.encode(&f.bgra, f.w as u16, f.h as u16, ColorType::Bgra)?;
    Ok(out)
}

pub struct CaptureOptions {
    pub params: Arc<CaptureParams>,
    pub keep_awake: bool,
}

/// Runs until `stop` is set or the window closes. Sends only changed frames,
/// plus a refresh every 3 s so a late-joining view always has a picture.
/// The phone can retune fps / picture scale / grayscale live via `params`.
pub fn spawn(
    id: u64,
    opts: CaptureOptions,
    tx: tokio::sync::mpsc::Sender<Vec<u8>>,
    stop: Arc<AtomicBool>,
) -> std::thread::JoinHandle<()> {
    std::thread::spawn(move || {
        // Execution state is per thread; this thread lives exactly as long as the session.
        if opts.keep_awake {
            power::keep_awake(true);
        }
        let params = opts.params;
        let mut prev: Vec<u8> = Vec::new();
        let mut last_sent = Instant::now() - Duration::from_secs(60);
        let h = crate::winlist::hwnd(id);

        while !stop.load(Ordering::Relaxed) {
            let t0 = Instant::now();
            let interval = Duration::from_millis(1000 / params.fps.load(Ordering::Relaxed).clamp(1, 60) as u64);
            if unsafe { !IsWindow(h).as_bool() } {
                let _ = tx.blocking_send(vec![protocol::FRAME_GONE]);
                break;
            }
            // Skip work entirely while the network is behind.
            if tx.capacity() > 0 {
                if let Some(mut f) = grab(h) {
                    let permil = params.scale_permil.load(Ordering::Relaxed);
                    if permil < 1000 {
                        f = downscale_to_width(&f, (f.w * permil / 1000).max(1));
                    }
                    if params.gray.load(Ordering::Relaxed) {
                        to_gray(&mut f.bgra);
                    }
                    let changed = f.bgra != prev;
                    if changed || last_sent.elapsed() > Duration::from_secs(3) {
                        if let Ok(jpg) = encode(&f, params.quality.load(Ordering::Relaxed)) {
                            let msg = protocol::binary(protocol::FRAME_VIDEO, id, f.w, f.h, &jpg);
                            if tx.try_send(msg).is_ok() {
                                last_sent = Instant::now();
                            }
                        }
                        prev = f.bgra;
                    }
                }
            }
            let spent = t0.elapsed();
            if spent < interval {
                std::thread::sleep(interval - spent);
            }
        }
        if opts.keep_awake {
            power::keep_awake(false);
        }
    })
}
