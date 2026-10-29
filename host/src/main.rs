// WinRelay host. Release builds run without a console window.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod capture;
mod config;
mod display;
mod input;
mod net;
mod power;
mod protocol;
mod server;
mod session;
mod winlist;

use std::net::{Ipv6Addr, SocketAddr};

use windows::Win32::Foundation::HWND;
use windows::Win32::UI::HiDpi::{SetProcessDpiAwarenessContext, DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2};
use windows::Win32::UI::Input::KeyboardAndMouse::{RegisterHotKey, MOD_ALT, MOD_CONTROL, MOD_NOREPEAT, MOD_SHIFT};
use windows::Win32::UI::WindowsAndMessaging::{GetMessageW, MSG, WM_HOTKEY};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    // All window and monitor coordinates are physical pixels from here on.
    unsafe {
        let _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    }

    // If the host crashed mid-session, put moved windows back on a physical screen.
    session::restore_all();

    let cfg = config::load();
    let port = cfg.port;
    let state = server::AppState::new(cfg);

    spawn_emergency_hotkey(state.clone());

    let listener = bind_dual_stack(port)?;
    tracing::info!("WinRelay listening on [::]:{port} (IPv4 and IPv6)");

    // Open the desktop UI in the default browser. It is served on loopback only.
    let _ = open::that(format!("http://localhost:{port}/ui"));

    let app = server::router(state);
    axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>()).await?;
    Ok(())
}

/// One socket for both IPv6 and IPv4. On Windows, [::] is IPv6-only unless
/// IPV6_V6ONLY is switched off, so we build the socket by hand.
fn bind_dual_stack(port: u16) -> anyhow::Result<tokio::net::TcpListener> {
    use socket2::{Domain, Protocol, Socket, Type};
    let sock = Socket::new(Domain::IPV6, Type::STREAM, Some(Protocol::TCP))?;
    sock.set_only_v6(false)?;
    sock.set_reuse_address(true)?;
    sock.bind(&SocketAddr::from((Ipv6Addr::UNSPECIFIED, port)).into())?;
    sock.listen(128)?;
    sock.set_nonblocking(true)?;
    let std_listener: std::net::TcpListener = sock.into();
    Ok(tokio::net::TcpListener::from_std(std_listener)?)
}

/// Ctrl+Alt+Shift+R ends every session and brings every moved window back.
fn spawn_emergency_hotkey(state: server::Shared) {
    std::thread::spawn(move || unsafe {
        let mods = MOD_CONTROL | MOD_ALT | MOD_SHIFT | MOD_NOREPEAT;
        if RegisterHotKey(HWND::default(), 1, mods, 'R' as u32).is_err() {
            tracing::warn!("Emergency hotkey is taken by another app");
            return;
        }
        let mut msg = MSG::default();
        while GetMessageW(&mut msg, HWND::default(), 0, 0).as_bool() {
            if msg.message == WM_HOTKEY {
                state.emergency();
            }
        }
    });
}
