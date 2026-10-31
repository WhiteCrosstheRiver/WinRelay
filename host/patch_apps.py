"""Patch protocol.rs / main.rs / server.rs for the app launcher."""
import io

# protocol.rs
p = 'src/protocol.rs'
s = io.open(p, encoding='utf-8').read()
orig = s
s = s.replace(
    "    /// Clipboard relay (phone bridges two PCs): read this PC's clipboard.\n"
    "    ClipGet,",
    "    /// App launcher: search Start-Menu apps, launch or close one.\n"
    "    AppsSearch { q: String },\n"
    "    AppLaunch { path: String },\n"
    "    AppClose { name: String },\n"
    "    /// Clipboard relay (phone bridges two PCs): read this PC's clipboard.\n"
    "    ClipGet,",
)
s = s.replace(
    "    /// ClipSet (and other clipboard writes) completed.\n"
    "    ClipOk,",
    "    /// ClipSet (and other clipboard writes) completed.\n"
    "    ClipOk,\n"
    "    /// Reply to AppsSearch; running apps come first.\n"
    "    Apps { q: String, items: Vec<crate::apps::AppInfo> },\n"
    "    /// AppLaunch / AppClose outcome.\n"
    "    AppResult { ok: bool, error: Option<String> },",
)
assert s != orig
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('protocol ok')

# main.rs
p = 'src/main.rs'
s = io.open(p, encoding='utf-8').read()
orig = s
s = s.replace("mod apps;", "")  # idempotence guard
s = s.replace("mod browser;", "mod apps;\nmod browser;")
assert s != orig
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('main ok')

# server.rs
p = 'src/server.rs'
s = io.open(p, encoding='utf-8').read()
orig = s
s = s.replace(
    "use crate::{browser, display, fs, net, power, session, winlist};",
    "use crate::{apps, browser, display, fs, net, power, session, winlist};",
)
s = s.replace(
    "                    ClientMsg::ClipGet => {",
    '''                    ClientMsg::AppsSearch { q } => {
                        let out2 = out.clone();
                        tokio::spawn(async move {
                            let items = tokio::task::spawn_blocking(move || apps::search(&q))
                                .await
                                .unwrap_or_default();
                            if let Ok(t) = serde_json::to_string(&HostMsg::Apps { q, items }) {
                                let _ = out2.send(Message::Text(t)).await;
                            }
                        });
                    }
                    ClientMsg::AppLaunch { path } => {
                        let id = next_fs_id();
                        let p = path.clone();
                        let r = tokio::task::spawn_blocking(move || apps::launch(&p)).await;
                        report_fs(&out, id, r).await;
                    }
                    ClientMsg::AppClose { name } => {
                        let id = next_fs_id();
                        let n = name.clone();
                        let r = tokio::task::spawn_blocking(move || apps::close(&n)).await;
                        // report_fs reports the count in the error slot on failure
                        // only; success carries no count, which is fine for the UI.
                        match r {
                            Ok(Ok(count)) => {
                                if let Ok(t) = serde_json::to_string(&HostMsg::AppResult { ok: true, error: None }) {
                                    let _ = out.send(Message::Text(t)).await;
                                }
                                let _ = count;
                            }
                            Ok(Err(e)) => {
                                if let Ok(t) = serde_json::to_string(&HostMsg::AppResult { ok: false, error: Some(e.to_string()) }) {
                                    let _ = out.send(Message::Text(t)).await;
                                }
                            }
                            Err(e) => {
                                if let Ok(t) = serde_json::to_string(&HostMsg::AppResult { ok: false, error: Some(e.to_string()) }) {
                                    let _ = out.send(Message::Text(t)).await;
                                }
                            }
                        }
                    }
                    ClientMsg::ClipGet => {''',
)
assert s != orig
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('server ok')
