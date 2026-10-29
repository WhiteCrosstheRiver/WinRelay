use crate::protocol::WinInfo;
use windows::core::PWSTR;
use windows::Win32::Foundation::{CloseHandle, BOOL, HWND, LPARAM, TRUE};
use windows::Win32::Graphics::Dwm::{DwmGetWindowAttribute, DWMWA_CLOAKED};
use windows::Win32::System::Threading::{
    OpenProcess, QueryFullProcessImageNameW, PROCESS_NAME_WIN32, PROCESS_QUERY_LIMITED_INFORMATION,
};
use windows::Win32::UI::WindowsAndMessaging::{
    EnumWindows, GetWindow, GetWindowLongPtrW, GetWindowTextLengthW, GetWindowTextW,
    GetWindowThreadProcessId, IsWindow, IsWindowVisible, GWL_EXSTYLE, GW_OWNER, WS_EX_TOOLWINDOW,
};

pub fn hwnd(id: u64) -> HWND {
    HWND(id as isize as *mut core::ffi::c_void)
}

unsafe extern "system" fn collect(h: HWND, lp: LPARAM) -> BOOL {
    let list = &mut *(lp.0 as *mut Vec<isize>);
    list.push(h.0 as isize);
    TRUE
}

/// Visible, top-level, titled windows a person would recognise as "an app window",
/// minus WinRelay itself and anything on the hidden-apps list.
pub fn list_windows(hidden: &[String]) -> Vec<WinInfo> {
    let mut raw: Vec<isize> = Vec::new();
    unsafe {
        let _ = EnumWindows(Some(collect), LPARAM(&mut raw as *mut Vec<isize> as isize));
    }
    let me = std::process::id();
    let mut out: Vec<WinInfo> = raw
        .into_iter()
        .filter_map(|id| {
            let h = HWND(id as *mut core::ffi::c_void);
            if !is_candidate(h) {
                return None;
            }
            let pid = pid_of(h);
            if pid == me {
                return None;
            }
            let exe = exe_name(pid).unwrap_or_default();
            if is_hidden(&exe, hidden) {
                return None;
            }
            Some(WinInfo {
                id: id as u64,
                title: title_of(h),
                app: pretty_app(&exe),
                exe,
            })
        })
        .collect();
    out.sort_by(|a, b| a.app.to_lowercase().cmp(&b.app.to_lowercase()));
    out
}

/// Re-checks a window id the phone sent us, so a phone can never open
/// a hidden app's window by guessing its id.
pub fn is_listable(id: u64, hidden: &[String]) -> bool {
    let h = hwnd(id);
    if !is_alive(h) || !is_candidate(h) {
        return false;
    }
    let pid = pid_of(h);
    pid != std::process::id() && !is_hidden(&exe_name(pid).unwrap_or_default(), hidden)
}

fn is_hidden(exe: &str, hidden: &[String]) -> bool {
    hidden.iter().any(|x| x.eq_ignore_ascii_case(exe))
}

pub fn is_alive(h: HWND) -> bool {
    unsafe { IsWindow(h).as_bool() }
}

fn is_candidate(h: HWND) -> bool {
    unsafe {
        if !IsWindowVisible(h).as_bool() {
            return false;
        }
        // Owned windows are dialogs and popups of another window.
        if let Ok(owner) = GetWindow(h, GW_OWNER) {
            if !owner.0.is_null() {
                return false;
            }
        }
        let ex = GetWindowLongPtrW(h, GWL_EXSTYLE) as u32;
        if ex & WS_EX_TOOLWINDOW.0 != 0 {
            return false;
        }
        // Cloaked windows are on another virtual desktop or suspended UWP frames.
        let mut cloaked: u32 = 0;
        if DwmGetWindowAttribute(
            h,
            DWMWA_CLOAKED,
            &mut cloaked as *mut u32 as *mut core::ffi::c_void,
            std::mem::size_of::<u32>() as u32,
        )
        .is_ok()
            && cloaked != 0
        {
            return false;
        }
        GetWindowTextLengthW(h) > 0
    }
}

pub fn title_of(h: HWND) -> String {
    unsafe {
        let len = GetWindowTextLengthW(h);
        if len <= 0 {
            return String::new();
        }
        let mut buf = vec![0u16; len as usize + 1];
        let n = GetWindowTextW(h, &mut buf);
        String::from_utf16_lossy(&buf[..n.max(0) as usize])
    }
}

fn pid_of(h: HWND) -> u32 {
    let mut pid = 0u32;
    unsafe {
        GetWindowThreadProcessId(h, Some(&mut pid));
    }
    pid
}

fn exe_name(pid: u32) -> Option<String> {
    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid).ok()?;
        let mut buf = [0u16; 1024];
        let mut len = buf.len() as u32;
        let result = QueryFullProcessImageNameW(handle, PROCESS_NAME_WIN32, PWSTR(buf.as_mut_ptr()), &mut len);
        let _ = CloseHandle(handle);
        result.ok()?;
        let path = String::from_utf16_lossy(&buf[..len as usize]);
        path.rsplit('\\').next().map(|s| s.to_string())
    }
}

/// The executable name (with .exe) of the process that owns the window.
pub fn exe_of(h: HWND) -> Option<String> {
    exe_name(pid_of(h))
}

/// "WindowsTerminal.exe" -> "Windows Terminal", "claude.exe" -> "Claude".
fn pretty_app(exe: &str) -> String {
    let stem = exe.strip_suffix(".exe").or_else(|| exe.strip_suffix(".EXE")).unwrap_or(exe);
    let known = match stem.to_lowercase().as_str() {
        "windowsterminal" => Some("Windows Terminal"),
        "code" => Some("Visual Studio Code"),
        "msedge" => Some("Microsoft Edge"),
        "chrome" => Some("Google Chrome"),
        "explorer" => Some("File Explorer"),
        "cmd" => Some("Command Prompt"),
        "powershell" | "pwsh" => Some("PowerShell"),
        _ => None,
    };
    if let Some(k) = known {
        return k.to_string();
    }
    let mut chars = stem.chars();
    match chars.next() {
        Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
        None => "Unknown app".to_string(),
    }
}
