//! A session = one window under phone control.
//! begin(): remember where the window was, move it (to the virtual monitor in
//! stealth), size it to the phone's shape. end(): put everything back.
//! Moved windows are also written to moved.json so a crash can be undone.

use crate::{config, display, protocol::Viewport, winlist};
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use windows::Win32::Foundation::{HWND, POINT, RECT};
use windows::Win32::System::Com::{CoCreateInstance, CoInitializeEx, CoUninitialize, CLSCTX_INPROC_SERVER, COINIT_APARTMENTTHREADED};
use windows::Win32::UI::HiDpi::GetDpiForWindow;
use windows::Win32::UI::Shell::{ITaskbarList, TaskbarList};
use windows::Win32::UI::WindowsAndMessaging::{
    ClipCursor, GetWindowPlacement, IsIconic, IsZoomed, SetWindowPlacement, SetWindowPos, ShowWindow,
    SWP_NOACTIVATE, SWP_NOZORDER, SW_RESTORE, WINDOWPLACEMENT, WINDOWPLACEMENT_FLAGS,
};

#[derive(Clone, Serialize, Deserialize)]
pub struct Saved {
    pub id: u64,
    pub show_cmd: u32,
    pub l: i32,
    pub t: i32,
    pub r: i32,
    pub b: i32,
    pub taskbar_hidden: bool,
}

pub struct Session {
    pub id: u64,
    pub title: String,
    pub saved: Saved,
    pub stealth: bool,
    pub on_virtual: bool,
    pub scale: f32,
}

pub struct Options<'a> {
    pub stealth: bool,
    pub hide_taskbar: bool,
    pub fence_cursor: bool,
    pub matchers: &'a str,
}

/// Rect the mouse is fenced to while a stealth session runs.
static FENCE: Mutex<Option<RECT>> = parking_lot::const_mutex(None);

pub fn begin(id: u64, vp: Viewport, scale: f32, o: &Options) -> anyhow::Result<Session> {
    let h = winlist::hwnd(id);
    if !winlist::is_alive(h) {
        anyhow::bail!("That window has closed on the PC.");
    }
    let virt = if o.stealth { display::virtual_monitor(o.matchers) } else { None };
    if o.stealth && virt.is_none() {
        anyhow::bail!(
            "Stealth needs the virtual display, and WinRelay can't find it. Turn it on from WinRelay on the PC, or connect without stealth."
        );
    }

    let mut saved = save_placement(id)?;
    if o.stealth && o.hide_taskbar {
        taskbar_button(id, false);
        saved.taskbar_hidden = true;
    }
    persist_add(&saved);

    let area = match &virt {
        Some(m) => m.work,
        None => display::work_area_of(h),
    };
    fit(h, area, vp, scale, virt.is_some());

    if o.stealth && o.fence_cursor {
        if let Some(r) = display::physical_bounds(o.matchers) {
            *FENCE.lock() = Some(r);
            refence();
        }
    }

    Ok(Session {
        id,
        title: winlist::title_of(h),
        saved,
        stealth: o.stealth,
        on_virtual: virt.is_some(),
        scale,
    })
}

/// Phone rotated: reshape the window.
pub fn refit(s: &Session, vp: Viewport, matchers: &str) {
    let h = winlist::hwnd(s.id);
    let area = if s.on_virtual {
        display::virtual_monitor(matchers).map(|m| m.work).unwrap_or_else(|| display::work_area_of(h))
    } else {
        display::work_area_of(h)
    };
    fit(h, area, vp, s.scale, s.on_virtual);
}

pub fn end(s: Session) {
    fence_off();
    restore(&s.saved);
    persist_remove(s.id);
}

/// Undo every move on record (crash recovery and the emergency hotkey).
pub fn restore_all() {
    fence_off();
    let list: Vec<Saved> = config::load_json("moved.json");
    for s in &list {
        restore(s);
    }
    config::save_json("moved.json", &Vec::<Saved>::new());
}

pub fn refence() {
    if let Some(r) = *FENCE.lock() {
        unsafe {
            let _ = ClipCursor(Some(&r as *const RECT));
        }
    }
}

fn fence_off() {
    *FENCE.lock() = None;
    unsafe {
        let _ = ClipCursor(None);
    }
}

/// Size the window to the phone's aspect ratio inside `area`.
/// Window logical size = phone logical size x scale, converted with the
/// target monitor's DPI, then shrunk to fit if needed.
fn fit(h: HWND, area: RECT, vp: Viewport, scale: f32, top_left: bool) {
    unsafe {
        if IsIconic(h).as_bool() || IsZoomed(h).as_bool() {
            let _ = ShowWindow(h, SW_RESTORE);
        }
        // Move first so the window adopts the target monitor's DPI.
        let _ = SetWindowPos(h, HWND::default(), area.left, area.top, 480, 640, SWP_NOZORDER | SWP_NOACTIVATE);
        let dpi = GetDpiForWindow(h).max(96) as f32 / 96.0;

        let mut w = vp.w.max(200.0) * scale * dpi;
        let mut ht = vp.h.max(200.0) * scale * dpi;
        let aw = (area.right - area.left) as f32;
        let ah = (area.bottom - area.top) as f32;
        let k = (aw / w).min(ah / ht).min(1.0);
        w *= k;
        ht *= k;

        let (x, y) = if top_left {
            (area.left, area.top)
        } else {
            (area.left + ((aw - w) / 2.0) as i32, area.top + ((ah - ht) / 2.0) as i32)
        };
        let _ = SetWindowPos(h, HWND::default(), x, y, w as i32, ht as i32, SWP_NOZORDER | SWP_NOACTIVATE);
    }
}

fn save_placement(id: u64) -> anyhow::Result<Saved> {
    let mut wp = WINDOWPLACEMENT {
        length: std::mem::size_of::<WINDOWPLACEMENT>() as u32,
        ..Default::default()
    };
    unsafe { GetWindowPlacement(winlist::hwnd(id), &mut wp)? };
    let r = wp.rcNormalPosition;
    Ok(Saved {
        id,
        show_cmd: wp.showCmd,
        l: r.left,
        t: r.top,
        r: r.right,
        b: r.bottom,
        taskbar_hidden: false,
    })
}

fn restore(s: &Saved) {
    let h = winlist::hwnd(s.id);
    if !winlist::is_alive(h) {
        return;
    }
    let wp = WINDOWPLACEMENT {
        length: std::mem::size_of::<WINDOWPLACEMENT>() as u32,
        flags: WINDOWPLACEMENT_FLAGS(0),
        showCmd: s.show_cmd,
        ptMinPosition: POINT { x: -1, y: -1 },
        ptMaxPosition: POINT { x: -1, y: -1 },
        rcNormalPosition: RECT { left: s.l, top: s.t, right: s.r, bottom: s.b },
    };
    unsafe {
        let _ = SetWindowPlacement(h, &wp);
    }
    if s.taskbar_hidden {
        taskbar_button(s.id, true);
    }
}

/// Show or hide a window's taskbar button. COM needs its own apartment, so this
/// runs on a short-lived thread.
fn taskbar_button(id: u64, show: bool) {
    let _ = std::thread::spawn(move || unsafe {
        let _ = CoInitializeEx(None, COINIT_APARTMENTTHREADED);
        if let Ok(tb) = CoCreateInstance::<_, ITaskbarList>(&TaskbarList, None, CLSCTX_INPROC_SERVER) {
            if tb.HrInit().is_ok() {
                let h = winlist::hwnd(id);
                let _ = if show { tb.AddTab(h) } else { tb.DeleteTab(h) };
            }
        }
        CoUninitialize();
    })
    .join();
}

fn persist_add(s: &Saved) {
    let mut list: Vec<Saved> = config::load_json("moved.json");
    list.retain(|x| x.id != s.id);
    list.push(s.clone());
    config::save_json("moved.json", &list);
}

fn persist_remove(id: u64) {
    let mut list: Vec<Saved> = config::load_json("moved.json");
    list.retain(|x| x.id != id);
    config::save_json("moved.json", &list);
}
