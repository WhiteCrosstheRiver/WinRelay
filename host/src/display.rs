use windows::core::PCWSTR;
use windows::Win32::Foundation::{BOOL, HWND, LPARAM, RECT, TRUE};
use windows::Win32::Graphics::Gdi::{
    EnumDisplayDevicesW, EnumDisplayMonitors, GetMonitorInfoW, MonitorFromWindow, DISPLAY_DEVICEW, HDC,
    HMONITOR, MONITORINFO, MONITORINFOEXW, MONITOR_DEFAULTTONEAREST,
};
use windows::Win32::UI::WindowsAndMessaging::{
    GetWindowRect, SetWindowPos, SWP_NOACTIVATE, SWP_NOSIZE, SWP_NOZORDER,
};

#[derive(Clone, Debug)]
pub struct Monitor {
    pub rect: RECT,
    pub work: RECT,
    /// e.g. \\.\DISPLAY3
    pub device: String,
    /// Display adapter name, e.g. "Virtual Display Driver"
    pub adapter: String,
}

fn wstr(buf: &[u16]) -> String {
    let n = buf.iter().position(|&c| c == 0).unwrap_or(buf.len());
    String::from_utf16_lossy(&buf[..n])
}

/// (device name, adapter description) for every display adapter output.
fn adapters() -> Vec<(String, String)> {
    let mut out = Vec::new();
    let mut i = 0u32;
    loop {
        let mut dd = DISPLAY_DEVICEW {
            cb: std::mem::size_of::<DISPLAY_DEVICEW>() as u32,
            ..Default::default()
        };
        let ok = unsafe { EnumDisplayDevicesW(PCWSTR::null(), i, &mut dd, 0) };
        if !ok.as_bool() {
            break;
        }
        out.push((wstr(&dd.DeviceName), wstr(&dd.DeviceString)));
        i += 1;
    }
    out
}

unsafe extern "system" fn on_monitor(h: HMONITOR, _: HDC, _: *mut RECT, lp: LPARAM) -> BOOL {
    let list = &mut *(lp.0 as *mut Vec<Monitor>);
    let mut mi = MONITORINFOEXW::default();
    mi.monitorInfo.cbSize = std::mem::size_of::<MONITORINFOEXW>() as u32;
    if GetMonitorInfoW(h, &mut mi as *mut MONITORINFOEXW as *mut MONITORINFO).as_bool() {
        list.push(Monitor {
            rect: mi.monitorInfo.rcMonitor,
            work: mi.monitorInfo.rcWork,
            device: wstr(&mi.szDevice),
            adapter: String::new(),
        });
    }
    TRUE
}

pub fn monitors() -> Vec<Monitor> {
    let mut list: Vec<Monitor> = Vec::new();
    unsafe {
        let _ = EnumDisplayMonitors(
            HDC::default(),
            None,
            Some(on_monitor),
            LPARAM(&mut list as *mut Vec<Monitor> as isize),
        );
    }
    let names = adapters();
    for m in &mut list {
        if let Some((_, desc)) = names.iter().find(|(dev, _)| dev.eq_ignore_ascii_case(&m.device)) {
            m.adapter = desc.clone();
        }
    }
    list
}

fn is_virtual(m: &Monitor, matchers: &str) -> bool {
    let name = m.adapter.to_lowercase();
    matchers
        .split(';')
        .map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
        .any(|s| name.contains(&s))
}

/// The virtual monitor the stealth session uses, if the driver is installed and on.
pub fn virtual_monitor(matchers: &str) -> Option<Monitor> {
    monitors().into_iter().find(|m| is_virtual(m, matchers))
}

/// Bounding box of the real screens, used to keep the mouse off the virtual monitor.
pub fn physical_bounds(matchers: &str) -> Option<RECT> {
    let phys: Vec<Monitor> = monitors().into_iter().filter(|m| !is_virtual(m, matchers)).collect();
    let first = phys.first()?;
    let mut r = first.rect;
    for m in &phys[1..] {
        r.left = r.left.min(m.rect.left);
        r.top = r.top.min(m.rect.top);
        r.right = r.right.max(m.rect.right);
        r.bottom = r.bottom.max(m.rect.bottom);
    }
    Some(r)
}

/// Full rect of the monitor a window is on.
pub fn monitor_rect_of(h: HWND) -> Option<RECT> {
    unsafe {
        let mon = MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST);
        let mut mi = MONITORINFO {
            cbSize: std::mem::size_of::<MONITORINFO>() as u32,
            ..Default::default()
        };
        if GetMonitorInfoW(mon, &mut mi).as_bool() {
            Some(mi.rcMonitor)
        } else {
            None
        }
    }
}

/// Shifts a window back on-screen if it stuck out. Apps clamp SetWindowPos to
/// their own minimum size, so a phone-shaped request can leave the real
/// window hanging over the screen edge — where SetCursorPos would silently
/// move every tap back onto the screen edge (taps "stuck").
pub fn clamp_window_into_monitor(h: HWND) {
    let Some(mon) = monitor_rect_of(h) else { return };
    let mut r = RECT::default();
    unsafe {
        let _ = GetWindowRect(h, &mut r);
    }
    let dx = if r.right > mon.right {
        mon.right - r.right
    } else if r.left < mon.left {
        mon.left - r.left
    } else {
        0
    };
    let dy = if r.bottom > mon.bottom {
        mon.bottom - r.bottom
    } else if r.top < mon.top {
        mon.top - r.top
    } else {
        0
    };
    if dx != 0 || dy != 0 {
        unsafe {
            let _ = SetWindowPos(
                h,
                HWND::default(),
                r.left + dx,
                r.top + dy,
                0,
                0,
                SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSIZE,
            );
        }
    }
}

/// Work area (screen minus taskbar) of the monitor a window is on.
pub fn work_area_of(h: HWND) -> RECT {
    unsafe {
        let mon = MonitorFromWindow(h, MONITOR_DEFAULTTONEAREST);
        let mut mi = MONITORINFO {
            cbSize: std::mem::size_of::<MONITORINFO>() as u32,
            ..Default::default()
        };
        if GetMonitorInfoW(mon, &mut mi).as_bool() {
            mi.rcWork
        } else {
            RECT { left: 0, top: 0, right: 1280, bottom: 720 }
        }
    }
}
