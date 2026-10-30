//! Text clipboard read/write for the phone relay and the URL grabber.
//! Split out of browser.rs so both the browser relay and the phone's
//! clipboard bridge use the same code.

use windows::core::PCWSTR;
use windows::Win32::Foundation::{HGLOBAL, HWND};
use windows::Win32::System::DataExchange::{CloseClipboard, GetClipboardData, OpenClipboard};
use windows::Win32::System::Memory::{GlobalLock, GlobalUnlock};

pub fn get_text() -> Option<String> {
    unsafe {
        if OpenClipboard(HWND::default()).is_err() {
            return None;
        }
        let out = (|| {
            // CF_UNICODETEXT = 13
            let h = GetClipboardData(13).ok()?;
            let p = GlobalLock(HGLOBAL(h.0)) as *const u16;
            if p.is_null() {
                return None;
            }
            let mut len = 0usize;
            while *p.add(len) != 0 {
                len += 1;
            }
            let slice = std::slice::from_raw_parts(p, len);
            let _ = GlobalUnlock(HGLOBAL(h.0));
            Some(String::from_utf16_lossy(slice))
        })();
        let _ = CloseClipboard();
        out
    }
}

pub fn set_text(s: &str) {
    use windows::Win32::Foundation::HANDLE;
    use windows::Win32::System::DataExchange::{EmptyClipboard, SetClipboardData};
    use windows::Win32::System::Memory::{GlobalAlloc, GMEM_MOVEABLE};
    unsafe {
        if OpenClipboard(HWND::default()).is_err() {
            return;
        }
        let mut v: Vec<u16> = s.encode_utf16().collect();
        v.push(0);
        let bytes = v.len() * 2;
        if let Ok(h) = GlobalAlloc(GMEM_MOVEABLE, bytes) {
            let p = GlobalLock(h) as *mut u16;
            if !p.is_null() {
                std::ptr::copy_nonoverlapping(v.as_ptr(), p, v.len());
                let _ = GlobalUnlock(h);
                // Ownership of the block moves to the clipboard; do not free it.
                let _ = SetClipboardData(13, HANDLE(h.0));
            }
        }
        let _ = CloseClipboard();
    }
}
