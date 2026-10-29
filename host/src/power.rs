use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
use windows::Win32::System::Power::{SetThreadExecutionState, ES_CONTINUOUS, ES_SYSTEM_REQUIRED};
use windows::Win32::System::Shutdown::LockWorkStation;
use windows::Win32::System::StationsAndDesktops::{
    CloseDesktop, OpenInputDesktop, SwitchDesktop, DESKTOP_CONTROL_FLAGS, DESKTOP_SWITCHDESKTOP,
};
use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, SC_MONITORPOWER, WM_SYSCOMMAND};

/// Keep the PC from sleeping while letting the screens turn off.
/// Applies to the calling thread until called again with `false` or the thread exits.
pub fn keep_awake(on: bool) {
    unsafe {
        let flags = if on { ES_CONTINUOUS | ES_SYSTEM_REQUIRED } else { ES_CONTINUOUS };
        SetThreadExecutionState(flags);
    }
}

/// Turn all monitors off. Posted (not sent) so a hung app can't block us.
pub fn screens_off() {
    unsafe {
        let broadcast = HWND(0xffff as _);
        let _ = PostMessageW(broadcast, WM_SYSCOMMAND, WPARAM(SC_MONITORPOWER as usize), LPARAM(2));
    }
}

/// True while the lock screen (or a UAC prompt) owns the input desktop.
/// Windows blocks capture and simulated typing there.
pub fn is_locked() -> bool {
    unsafe {
        match OpenInputDesktop(DESKTOP_CONTROL_FLAGS(0), false, DESKTOP_SWITCHDESKTOP) {
            Ok(desk) => {
                let usable = SwitchDesktop(desk).is_ok();
                let _ = CloseDesktop(desk);
                !usable
            }
            Err(_) => true,
        }
    }
}

pub fn lock() {
    unsafe {
        let _ = LockWorkStation();
    }
}
