//! Turns phone input into real Windows input aimed at the session window.
//! One worker thread per connection keeps keystrokes strictly in order.

use crate::{capture, power, protocol::TapKind, session};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{channel, RecvTimeoutError, Sender};
use std::sync::Arc;
use std::time::{Duration, Instant};
use windows::Win32::Foundation::{HWND, POINT};
use windows::Win32::System::Threading::{AttachThreadInput, GetCurrentThreadId};
use windows::Win32::UI::Input::KeyboardAndMouse::*;
use windows::Win32::UI::WindowsAndMessaging::{
    BringWindowToTop, ClipCursor, GetCursorPos, GetForegroundWindow, GetWindowThreadProcessId,
    SetCursorPos, SetForegroundWindow,
};

pub enum Cmd {
    Target(Option<u64>),
    Text(String),
    Key(String),
    Tap { x: f32, y: f32, kind: TapKind },
    Scroll { dy: i32, x: Option<f32>, y: Option<f32> },
}

/// `screens_off` is shared with the session: injected input wakes the monitors,
/// so after 1.5 s of quiet we switch them off again.
pub fn spawn_worker(screens_off: Arc<AtomicBool>) -> Sender<Cmd> {
    let (tx, rx) = channel::<Cmd>();
    std::thread::spawn(move || {
        let mut target: Option<u64> = None;
        let mut woke_screens = false;
        let mut parked: Option<POINT> = None;
        let mut last_scroll: Option<Instant> = None;
        loop {
            match rx.recv_timeout(Duration::from_millis(1500)) {
                Ok(Cmd::Target(t)) => {
                    target = t;
                    unpark(&mut parked, &mut last_scroll);
                }
                Ok(cmd) => {
                    if let Some(id) = target {
                        run(crate::winlist::hwnd(id), cmd, &mut parked, &mut last_scroll);
                        woke_screens = true;
                    }
                }
                Err(RecvTimeoutError::Timeout) => {
                    unpark(&mut parked, &mut last_scroll);
                    if woke_screens && target.is_some() && screens_off.load(Ordering::Relaxed) {
                        power::screens_off();
                    }
                    woke_screens = false;
                }
                Err(RecvTimeoutError::Disconnected) => break,
            }
        }
    });
    tx
}

fn run(h: HWND, cmd: Cmd, parked: &mut Option<POINT>, last_scroll: &mut Option<Instant>) {
    match cmd {
        Cmd::Text(s) => {
            focus(h);
            type_text(&s);
        }
        Cmd::Key(k) => {
            focus(h);
            key(&k);
        }
        Cmd::Tap { x, y, kind } => {
            // Without foreground, the first tap only activates the window and
            // the click is swallowed — taps would feel "stuck".
            focus(h);
            let r = capture::visible_rect(h);
            let mut px = r.left + ((r.right - r.left) as f32 * x.clamp(0.0, 1.0)) as i32;
            let mut py = r.top + ((r.bottom - r.top) as f32 * y.clamp(0.0, 1.0)) as i32;
            // A click on an off-screen part would be clamped by SetCursorPos
            // and land at the screen edge — keep it on the window's monitor.
            if let Some(mon) = crate::display::monitor_rect_of(h) {
                px = px.clamp(mon.left, (mon.right - 1).max(mon.left));
                py = py.clamp(mon.top, (mon.bottom - 1).max(mon.top));
            }
            at_point(px, py, || click(kind));
        }
        Cmd::Scroll { dy, x, y } => scroll_at(h, dy, x, y, parked, last_scroll),
        Cmd::Target(_) => {}
    }
}

/// Bring the target window to the foreground so keystrokes land in it.
/// Windows restricts focus stealing; attaching to the current foreground
/// thread's input queue is the reliable, side-effect-free way around it.
pub fn focus(h: HWND) {
    unsafe {
        let fg = GetForegroundWindow();
        if fg == h {
            return;
        }
        let fg_thread = GetWindowThreadProcessId(fg, None);
        let me = GetCurrentThreadId();
        let attached = fg_thread != 0 && fg_thread != me && AttachThreadInput(me, fg_thread, true).as_bool();
        let _ = SetForegroundWindow(h);
        let _ = BringWindowToTop(h);
        if attached {
            let _ = AttachThreadInput(me, fg_thread, false);
        }
        std::thread::sleep(Duration::from_millis(15));
    }
}

fn kbd(vk: VIRTUAL_KEY, scan: u16, flags: KEYBD_EVENT_FLAGS) -> INPUT {
    INPUT {
        r#type: INPUT_KEYBOARD,
        Anonymous: INPUT_0 {
            ki: KEYBDINPUT { wVk: vk, wScan: scan, dwFlags: flags, time: 0, dwExtraInfo: 0 },
        },
    }
}

fn mouse(flags: MOUSE_EVENT_FLAGS, data: i32) -> INPUT {
    INPUT {
        r#type: INPUT_MOUSE,
        Anonymous: INPUT_0 {
            mi: MOUSEINPUT { dx: 0, dy: 0, mouseData: data as _, dwFlags: flags, time: 0, dwExtraInfo: 0 },
        },
    }
}

fn send(inputs: &[INPUT]) {
    for chunk in inputs.chunks(200) {
        unsafe {
            SendInput(chunk, std::mem::size_of::<INPUT>() as i32);
        }
    }
}

fn tap_vk(vk: VIRTUAL_KEY, ext: bool, out: &mut Vec<INPUT>) {
    let e = if ext { KEYEVENTF_EXTENDEDKEY } else { KEYBD_EVENT_FLAGS(0) };
    out.push(kbd(vk, 0, e));
    out.push(kbd(vk, 0, e | KEYEVENTF_KEYUP));
}

/// Unicode typing works for every language and keyboard layout.
/// "\n" becomes a real Return key; "\t" a real Tab.
pub fn type_text(s: &str) {
    let mut v = Vec::with_capacity(s.len() * 2);
    for unit in s.encode_utf16() {
        match unit {
            0x0A => tap_vk(VK_RETURN, false, &mut v),
            0x0D => {}
            0x09 => tap_vk(VK_TAB, false, &mut v),
            u => {
                v.push(kbd(VIRTUAL_KEY(0), u, KEYEVENTF_UNICODE));
                v.push(kbd(VIRTUAL_KEY(0), u, KEYEVENTF_UNICODE | KEYEVENTF_KEYUP));
            }
        }
    }
    send(&v);
}

pub fn key(name: &str) {
    let (mods, vk, ext): (&[VIRTUAL_KEY], VIRTUAL_KEY, bool) = match name {
        "enter" => (&[], VK_RETURN, false),
        "shift_enter" => (&[VK_SHIFT], VK_RETURN, false),
        "ctrl_enter" => (&[VK_CONTROL], VK_RETURN, false),
        "backspace" => (&[], VK_BACK, false),
        "esc" => (&[], VK_ESCAPE, false),
        "tab" => (&[], VK_TAB, false),
        "shift_tab" => (&[VK_SHIFT], VK_TAB, false),
        "ctrl_c" => (&[VK_CONTROL], VIRTUAL_KEY(0x43), false),
        "ctrl_v" => (&[VK_CONTROL], VIRTUAL_KEY(0x56), false),
        "ctrl_z" => (&[VK_CONTROL], VIRTUAL_KEY(0x5A), false),
        "ctrl_l" => (&[VK_CONTROL], VIRTUAL_KEY(0x4C), false),
        "up" => (&[], VK_UP, true),
        "down" => (&[], VK_DOWN, true),
        "left" => (&[], VK_LEFT, true),
        "right" => (&[], VK_RIGHT, true),
        "home" => (&[], VK_HOME, true),
        "end" => (&[], VK_END, true),
        "pgup" => (&[], VK_PRIOR, true),
        "pgdn" => (&[], VK_NEXT, true),
        "delete" => (&[], VK_DELETE, true),
        _ => return,
    };
    let mut v = Vec::new();
    for m in mods {
        v.push(kbd(*m, 0, KEYBD_EVENT_FLAGS(0)));
    }
    tap_vk(vk, ext, &mut v);
    for m in mods.iter().rev() {
        v.push(kbd(*m, 0, KEYEVENTF_KEYUP));
    }
    send(&v);
}

/// Mouse input goes to whatever is under the cursor, so we briefly move it
/// to the target point (lifting the stealth fence), act, then put it back.
fn at_point<F: FnOnce()>(x: i32, y: i32, act: F) {
    unsafe {
        let mut old = POINT::default();
        let _ = GetCursorPos(&mut old);
        let _ = ClipCursor(None);
        let _ = SetCursorPos(x, y);
        act();
        std::thread::sleep(Duration::from_millis(20));
        let _ = SetCursorPos(old.x, old.y);
    }
    session::refence();
}

/// Wheel at the finger's position. During a fast flick the cursor stays
/// parked on the point (restoring it per notch would stutter the stream of
/// wheel events and drag the serial worker); it returns home once scrolling
/// goes quiet. `state` lives in the worker thread.
fn scroll_at(
    h: HWND,
    dy: i32,
    x: Option<f32>,
    y: Option<f32>,
    parked: &mut Option<POINT>,
    last_scroll: &mut Option<Instant>,
) {
    let r = capture::visible_rect(h);
    let fx = x.unwrap_or(0.5).clamp(0.0, 1.0);
    let fy = y.unwrap_or(0.5).clamp(0.0, 1.0);
    let px = r.left + ((r.right - r.left) as f32 * fx) as i32;
    let py = r.top + ((r.bottom - r.top) as f32 * fy) as i32;
    let now = Instant::now();
    let quiet = matches!(last_scroll, Some(t) if now.duration_since(*t) > Duration::from_millis(300));
    if quiet {
        // New scroll sequence: the target window must be foreground, or the
        // synthetic wheel goes to whatever window currently has focus (the
        // classic "some apps just don't scroll" bug).
        focus(h);
    }
    unsafe {
        if quiet || parked.is_none() {
            // (Re)take the cursor: remember where it came from only when not
            // already parked, so the home position survives a flick.
            if parked.is_none() {
                let mut old = POINT::default();
                let _ = GetCursorPos(&mut old);
                *parked = Some(old);
            }
            let _ = ClipCursor(None);
            let _ = SetCursorPos(px, py);
        }
        wheel(dy);
    }
    *last_scroll = Some(now);
    let _ = h;
}

/// Puts the parked cursor home after scrolling went quiet.
fn unpark(parked: &mut Option<POINT>, last_scroll: &mut Option<Instant>) {
    let due = matches!(last_scroll, Some(t) if Instant::now().duration_since(*t) > Duration::from_millis(300));
    if due {
        if let Some(p) = parked.take() {
            unsafe {
                let _ = SetCursorPos(p.x, p.y);
            }
            session::refence();
        }
        *last_scroll = None;
    }
}

fn click(kind: TapKind) {
    match kind {
        TapKind::Left => send(&[mouse(MOUSEEVENTF_LEFTDOWN, 0), mouse(MOUSEEVENTF_LEFTUP, 0)]),
        TapKind::Right => send(&[mouse(MOUSEEVENTF_RIGHTDOWN, 0), mouse(MOUSEEVENTF_RIGHTUP, 0)]),
        TapKind::Double => send(&[
            mouse(MOUSEEVENTF_LEFTDOWN, 0),
            mouse(MOUSEEVENTF_LEFTUP, 0),
            mouse(MOUSEEVENTF_LEFTDOWN, 0),
            mouse(MOUSEEVENTF_LEFTUP, 0),
        ]),
    }
}

fn wheel(notches: i32) {
    send(&[mouse(MOUSEEVENTF_WHEEL, notches.clamp(-10, 10) * 120)]);
}
