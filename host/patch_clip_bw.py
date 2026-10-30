"""Patch host for clip relay + pure black-white mode."""
import io

# ---- browser.rs: use shared clipboard module ----
p = 'src/browser.rs'
s = io.open(p, encoding='utf-8').read()
start = s.index('fn clipboard_text()')
end = s.index('/// The URL the browser window')
s = s[:start] + s[end:]
s = s.replace('use crate::input;', 'use crate::{clipboard, input};')
s = s.replace('let saved = clipboard_text();', 'let saved = clipboard::get_text();')
s = s.replace('let text = clipboard_text();', 'let text = clipboard::get_text();')
s = s.replace('set_clipboard_text(&saved);', 'clipboard::set_text(&saved);')
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('browser ok')

# ---- main.rs: module ----
p = 'src/main.rs'
s = io.open(p, encoding='utf-8').read()
s = s.replace('mod browser;\nmod capture;', 'mod browser;\nmod capture;\nmod clipboard;')
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('main ok')

# ---- protocol.rs: clip messages + bw fields ----
p = 'src/protocol.rs'
s = io.open(p, encoding='utf-8').read()
s = s.replace('''        /// Stream overrides, applied for this session (phone saves bandwidth):
        /// capture frame rate, picture downscale (1.0 = full size), grayscale.
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
    },''', '''        /// Stream overrides, applied for this session (phone saves bandwidth):
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
    },''')
s = s.replace('''    Stream {
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
    },''', '''    Stream {
        #[serde(default)]
        fps: Option<u32>,
        #[serde(default)]
        pic_scale: Option<f32>,
        #[serde(default)]
        gray: Option<bool>,
        #[serde(default)]
        bw: Option<bool>,
    },
    /// Clipboard relay (phone bridges two PCs): read this PC's clipboard.
    ClipGet,
    /// Write this PC's clipboard so a following Ctrl+V pastes the text.
    ClipSet { s: String },''')
s = s.replace('''    FsMeta { id: u64, size: u64 },
    FsUploadReady { id: u64 },''', '''    FsMeta { id: u64, size: u64 },
    FsUploadReady { id: u64 },
    /// Reply to ClipGet; empty string when the clipboard holds no text.
    ClipText { s: String },
    /// ClipSet (and other clipboard writes) completed.
    ClipOk,''')
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('protocol ok')

# ---- capture.rs: bw mode ----
p = 'src/capture.rs'
s = io.open(p, encoding='utf-8').read()
s = s.replace('''/// BT.601 luma in place; the alpha byte is left untouched.
pub fn to_gray(bgra: &mut [u8]) {
    for px in bgra.chunks_exact_mut(4) {
        let l = (0.299 * px[2] as f32 + 0.587 * px[1] as f32 + 0.114 * px[0] as f32) as u8;
        px[0] = l;
        px[1] = l;
        px[2] = l;
    }
}''', '''/// BT.601 luma in place; the alpha byte is left untouched.
pub fn to_gray(bgra: &mut [u8]) {
    for px in bgra.chunks_exact_mut(4) {
        let l = (0.299 * px[2] as f32 + 0.587 * px[1] as f32 + 0.114 * px[0] as f32) as u8;
        px[0] = l;
        px[1] = l;
        px[2] = l;
    }
}

/// Pure black-and-white: luma thresholded to two values. The extreme tier —
/// only useful for plain text / simple UI, where it shrinks frames further.
pub fn to_bw(bgra: &mut [u8]) {
    for px in bgra.chunks_exact_mut(4) {
        let l = 0.299 * px[2] as f32 + 0.587 * px[1] as f32 + 0.114 * px[0] as f32;
        let v = if l >= 128.0 { 255 } else { 0 };
        px[0] = v;
        px[1] = v;
        px[2] = v;
    }
}''')
s = s.replace('''    /// Picture width as permille of the window's own width (1000 = full).
    pub scale_permil: AtomicU32,
    pub gray: AtomicBool,
}''', '''    /// Picture width as permille of the window's own width (1000 = full).
    pub scale_permil: AtomicU32,
    pub gray: AtomicBool,
    pub bw: AtomicBool,
}''')
s = s.replace('''            scale_permil: AtomicU32::new(1000),
            gray: AtomicBool::new(false),
        })''', '''            scale_permil: AtomicU32::new(1000),
            gray: AtomicBool::new(false),
            bw: AtomicBool::new(false),
        })''')
s = s.replace('''    pub fn set(&self, fps: Option<u32>, pic_scale: Option<f32>, gray: Option<bool>) {
        if let Some(f) = fps {
            self.fps.store(f.clamp(1, 60), Ordering::Relaxed);
        }
        if let Some(s) = pic_scale {
            self.scale_permil.store((s.clamp(0.05, 1.0) * 1000.0) as u32, Ordering::Relaxed);
        }
        if let Some(g) = gray {
            self.gray.store(g, Ordering::Relaxed);
        }
    }''', '''    pub fn set(&self, fps: Option<u32>, pic_scale: Option<f32>, gray: Option<bool>, bw: Option<bool>) {
        if let Some(f) = fps {
            self.fps.store(f.clamp(1, 60), Ordering::Relaxed);
        }
        if let Some(s) = pic_scale {
            self.scale_permil.store((s.clamp(0.05, 1.0) * 1000.0) as u32, Ordering::Relaxed);
        }
        if let Some(g) = gray {
            self.gray.store(g, Ordering::Relaxed);
        }
        if let Some(b) = bw {
            self.bw.store(b, Ordering::Relaxed);
        }
    }''')
s = s.replace('''                    if params.gray.load(Ordering::Relaxed) {
                        to_gray(&mut f.bgra);
                    }''', '''                    if params.bw.load(Ordering::Relaxed) {
                        to_bw(&mut f.bgra);
                    } else if params.gray.load(Ordering::Relaxed) {
                        to_gray(&mut f.bgra);
                    }''')
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('capture ok')
