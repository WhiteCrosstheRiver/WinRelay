"""Patch server.rs: bw param plumbing + clip relay handlers."""
import io

p = 'src/server.rs'
s = io.open(p, encoding='utf-8').read()
orig = s

s = s.replace(
    "                    ClientMsg::Open { id, stealth, viewport, scale, fps, pic_scale, gray } => {",
    "                    ClientMsg::Open { id, stealth, viewport, scale, fps, pic_scale, gray, bw } => {",
)
s = s.replace(
    "                                let params = capture::CaptureParams::new(cfg.max_fps, cfg.jpeg_quality);\n"
    "                                params.set(fps, pic_scale, gray);",
    "                                let params = capture::CaptureParams::new(cfg.max_fps, cfg.jpeg_quality);\n"
    "                                params.set(fps, pic_scale, gray, bw);",
)
s = s.replace(
    "                    ClientMsg::Stream { fps, pic_scale, gray } => {\n"
    "                        if let Some(l) = &live {\n"
    "                            l.params.set(fps, pic_scale, gray);\n"
    "                        }\n"
    "                    }",
    "                    ClientMsg::Stream { fps, pic_scale, gray, bw } => {\n"
    "                        if let Some(l) = &live {\n"
    "                            l.params.set(fps, pic_scale, gray, bw);\n"
    "                        }\n"
    "                    }\n"
    "                    ClientMsg::ClipGet => {\n"
    "                        let out2 = out.clone();\n"
    "                        tokio::spawn(async move {\n"
    "                            let text = tokio::task::spawn_blocking(crate::clipboard::get_text)\n"
    "                                .await\n"
    "                                .unwrap_or_else(|_| Some(String::new()))\n"
    "                                .unwrap_or_default();\n"
    "                            if let Ok(t) = serde_json::to_string(&HostMsg::ClipText { s: text }) {\n"
    "                                let _ = out2.send(Message::Text(t)).await;\n"
    "                            }\n"
    "                        });\n"
    "                    }\n"
    "                    ClientMsg::ClipSet { s: text } => {\n"
    "                        let out2 = out.clone();\n"
    "                        tokio::spawn(async move {\n"
    "                            let ok = tokio::task::spawn_blocking(move || {\n"
    "                                crate::clipboard::set_text(&text);\n"
    "                                true\n"
    "                            })\n"
    "                            .await\n"
    "                            .unwrap_or(false);\n"
    "                            if ok {\n"
    "                                if let Ok(t) = serde_json::to_string(&HostMsg::ClipOk) {\n"
    "                                    let _ = out2.send(Message::Text(t)).await;\n"
    "                                }\n"
    "                            }\n"
    "                        });\n"
    "                    }",
)

assert s != orig, "no replacement applied"
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('server patched')
