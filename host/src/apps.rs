//! App launcher: enumerate Start-Menu shortcuts, search them, launch, and
//! close running apps. Names come from the .lnk file names; launching runs
//! the shortcut itself via ShellExecute (Windows resolves the target).

use serde::Serialize;
use std::fs;
use std::path::Path;
use std::sync::Mutex;
use std::time::{Duration, Instant};

#[derive(Serialize, Clone, Debug)]
pub struct AppInfo {
    pub name: String,
    /// Full path of the .lnk shortcut; ShellExecute opens it directly.
    pub path: String,
    pub running: bool,
}

struct Cache {
    at: Instant,
    items: Vec<(String, String)>, // (display name, lnk path)
}

static CACHE: Mutex<Option<Cache>> = Mutex::new(None);

fn start_menu_dirs() -> Vec<std::path::PathBuf> {
    let mut out = Vec::new();
    if let Ok(pd) = std::env::var("ProgramData") {
        out.push(Path::new(&pd).join("Microsoft\\Windows\\Start Menu\\Programs"));
    }
    if let Ok(ad) = std::env::var("APPDATA") {
        out.push(Path::new(&ad).join("Microsoft\\Windows\\Start Menu\\Programs"));
    }
    out
}

fn scan() -> Vec<(String, String)> {
    let mut out = Vec::new();
    let mut stack: Vec<std::path::PathBuf> = start_menu_dirs().into_iter().filter(|d| d.exists()).collect();
    while let Some(dir) = stack.pop() {
        if let Ok(rd) = fs::read_dir(&dir) {
            for e in rd.flatten() {
                let p = e.path();
                if p.is_dir() {
                    stack.push(p);
                } else if p.extension().map(|x| x.eq_ignore_ascii_case("lnk")).unwrap_or(false) {
                    let name = p.file_stem().map(|s| s.to_string_lossy().to_string()).unwrap_or_default();
                    // Hide the uninstall noise; real apps keep their launchers.
                    if !name.is_empty() && !name.to_lowercase().contains("uninstall") {
                        out.push((name, p.to_string_lossy().to_string()));
                    }
                }
            }
        }
    }
    out.sort_by(|a, b| a.0.to_lowercase().cmp(&b.0.to_lowercase()));
    out.dedup_by(|a, b| a.0.eq_ignore_ascii_case(&b.0));
    out
}

fn cached() -> Vec<(String, String)> {
    let mut c = CACHE.lock().unwrap();
    if let Some(c) = c.as_ref() {
        if c.at.elapsed() < Duration::from_secs(300) {
            return c.items.clone();
        }
    }
    let items = scan();
    *c = Some(Cache { at: Instant::now(), items: items.clone() });
    items
}

/// Lowercased app/title of every visible window, for running-state matches.
fn running_names() -> Vec<String> {
    crate::winlist::list_windows(&[])
        .into_iter()
        .flat_map(|w| [w.app.to_lowercase(), w.title.to_lowercase()])
        .collect()
}

fn is_running(name: &str, running: &[String]) -> bool {
    let n = name.to_lowercase();
    running.iter().any(|r| r.contains(&n))
}

/// Search apps by substring (empty query = all, running ones first).
pub fn search(q: &str) -> Vec<AppInfo> {
    let ql = q.trim().to_lowercase();
    let running = running_names();
    let mut out: Vec<AppInfo> = cached()
        .iter()
        .filter(|(name, _)| ql.is_empty() || name.to_lowercase().contains(&ql))
        .map(|(name, path)| AppInfo {
            name: name.clone(),
            path: path.clone(),
            running: is_running(name, &running),
        })
        .take(60)
        .collect();
    out.sort_by(|a, b| b.running.cmp(&a.running).then(a.name.to_lowercase().cmp(&b.name.to_lowercase())));
    out
}

/// Launches a Start-Menu shortcut via ShellExecute.
pub fn launch(path: &str) -> anyhow::Result<()> {
    use windows::core::PCWSTR;
    use windows::Win32::UI::Shell::ShellExecuteW;
    use windows::Win32::UI::WindowsAndMessaging::SW_SHOWNORMAL;
    let wide: Vec<u16> = path.encode_utf16().chain(std::iter::once(0)).collect();
    unsafe {
        let r = ShellExecuteW(None, PCWSTR::null(), PCWSTR(wide.as_ptr()), None, None, SW_SHOWNORMAL);
        if r.0 as usize <= 32 {
            anyhow::bail!("Launch failed (code {})", r.0 as usize);
        }
    }
    Ok(())
}

/// Closes every top-level window whose app or title contains `name`
/// (WM_CLOSE — graceful, apps still get to prompt about unsaved work).
/// Returns how many windows were told to close.
pub fn close(name: &str) -> anyhow::Result<usize> {
    use windows::Win32::Foundation::{LPARAM, WPARAM};
    use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, WM_CLOSE};
    let n = name.to_lowercase();
    let mut closed = 0;
    for w in crate::winlist::list_windows(&[]) {
        if w.app.to_lowercase().contains(&n) || w.title.to_lowercase().contains(&n) {
            unsafe {
                let _ = PostMessageW(crate::winlist::hwnd(w.id), WM_CLOSE, WPARAM(0), LPARAM(0));
            }
            closed += 1;
        }
    }
    if closed == 0 {
        anyhow::bail!("No open window matches '{}'.", name);
    }
    Ok(closed)
}
