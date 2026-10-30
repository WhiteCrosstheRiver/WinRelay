//! Browser windows: detect them and read the URL they are showing, so the
//! phone can open the same page in its own WebView (mobile web, native touch)
//! and push navigations back here.
//!
//! URL grabbing works on every Chromium/Firefox-family browser: focus the
//! window, Ctrl+L (focus the address bar), Ctrl+C, read the clipboard, then
//! restore the user's clipboard and close the dropdown with Esc.

use crate::{clipboard, input};
use std::time::Duration;
use windows::Win32::Foundation::HWND;

/// Executable names (lowercase, without .exe) of browsers the phone can take
/// over. Kept in sync with the phone app's list in models.dart.
const BROWSER_EXES: &[&str] = &[
    // Chromium family, international
    "chrome", "msedge", "brave", "vivaldi", "opera", "arc", "duckduckgo", "chromium",
    "thorium", "slimjet", "iridium", "centbrowser", "whale", "yandex", "browser",
    // Firefox family
    "firefox", "zen", "waterfox", "librewolf", "palemoon",
    // Chinese browsers
    "qqbrowser", "360se", "360chrome", "maxthon", "sogouexplorer", "baidubrowser",
    "ucbrowser", "liebao", "2345explorer", "twinkstar", "quark-browser", "quarkpc",
];

pub fn is_browser_exe(exe: &str) -> bool {
    let stem = exe.to_lowercase();
    let stem = stem.strip_suffix(".exe").unwrap_or(&stem);
    BROWSER_EXES.contains(&stem)
}

fn looks_like_url(s: &str) -> bool {
    let s = s.trim();
    let lower = s.to_lowercase();
    let scheme_ok = lower.starts_with("http://")
        || lower.starts_with("https://")
        || lower.starts_with("about:")
        || lower.starts_with("edge://")
        || lower.starts_with("chrome://")
        || lower.starts_with("firefox:")
        || lower.starts_with("file://");
    (scheme_ok || (s.contains('.') && !s.contains(' '))) && s.len() < 2048 && !s.is_empty()
}

/// The URL the browser window is currently showing, or None.
/// Grabs it via the address bar; the user's clipboard is restored afterwards.
pub fn current_url(h: HWND) -> Option<String> {
    let saved = clipboard::get_text();
    input::focus(h);
    input::key("ctrl_l");
    std::thread::sleep(Duration::from_millis(90));
    input::key("ctrl_c");
    std::thread::sleep(Duration::from_millis(160));
    let text = clipboard::get_text();
    if let Some(saved) = saved {
        std::thread::sleep(Duration::from_millis(30));
        clipboard::set_text(&saved);
    }
    input::key("esc");
    let url = text?.trim().to_string();
    if looks_like_url(&url) {
        Some(url)
    } else {
        None
    }
}

/// Point the browser's address bar at `url` (the phone pushes navigation here).
pub fn navigate(h: HWND, url: &str) {
    input::focus(h);
    input::key("ctrl_l");
    std::thread::sleep(Duration::from_millis(90));
    input::type_text(url);
    std::thread::sleep(Duration::from_millis(40));
    input::key("enter");
}
