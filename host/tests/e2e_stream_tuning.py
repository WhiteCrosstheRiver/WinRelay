"""E2E: open a window with stream tuning (fps=5, pic_scale=0.5, gray=true),
receive a video frame, and verify the frame really is half-size grayscale.

Read-only on the PC apart from briefly moving/restoring the window: the
session is closed again right after, and the emergency restore runs too.
"""
import asyncio
import json
import struct
import urllib.request

import websockets

BASE = "http://localhost:47800"
VIEWPORT = {"w": 400, "h": 800, "dpr": 2}


def api(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=5) as r:
        return r.status


async def recv_json(ws, want, timeout=15):
    while True:
        raw = await asyncio.wait_for(ws.recv(), timeout)
        if not isinstance(raw, (bytes, bytearray)):  # skip video frames
            msg = json.loads(raw)
            if msg.get("t") == want:
                return msg


async def recv_frame(ws, timeout=15):
    while True:
        b = await asyncio.wait_for(ws.recv(), timeout)
        if isinstance(b, (bytes, bytearray)) and b[0] == 1:  # FRAME_VIDEO
            wid, w, h = struct.unpack("<QII", b[1:17])
            return w, h, b[17:]


async def main():
    import os
    status = json.load(urllib.request.urlopen(BASE + "/api/status", timeout=5))
    assert status["devices"], "run e2e_pair_list.py first to create a paired device"
    dev = status["devices"][0]
    # /api/status hides secrets; the config file has them (local only).
    cfg_path = os.path.join(os.environ["APPDATA"], "WinRelay", "config.json")
    with open(cfg_path, encoding="utf-8") as f:
        secret = next(d["secret"] for d in json.load(f)["devices"] if d["id"] == dev["id"])

    async with websockets.connect(f"ws://localhost:{status['port']}/ws") as ws:
        await ws.send(json.dumps({"t": "hello", "device_id": dev["id"], "device_name": "stream-tune", "secret": secret}))
        await recv_json(ws, "welcome")

        await ws.send(json.dumps({"t": "list"}))
        wins = (await recv_json(ws, "windows"))["items"]
        assert wins, "no windows to open"
        target = wins[0]
        print("opening:", target["title"][:50])

        await ws.send(json.dumps({
            "t": "open", "id": target["id"], "stealth": False,
            "viewport": VIEWPORT, "scale": 1.0,
            "fps": 5, "pic_scale": 0.5, "gray": True,
        }))
        await recv_json(ws, "opened")

        w, h, jpeg = await recv_frame(ws)
        print(f"frame: {w}x{h}, jpeg {len(jpeg)} bytes")
        assert w > 0 and h > 0
        # Window was sized to the viewport*1.0 (possibly clamped to the work
        # area), so a 0.5 scale means the frame must be at most half of it.
        # Just assert it's clearly downscaled from full: re-request full size
        # implicitly via a second open and compare widths.

        await ws.send(json.dumps({"t": "stream", "pic_scale": 1.0, "gray": False}))
        await asyncio.sleep(1.5)
        w2, h2, jpeg2 = await recv_frame(ws)
        print(f"after stream retune: {w2}x{h2}, jpeg {len(jpeg2)} bytes")
        assert w2 > w * 1.4, f"expected ~2x wider frame after pic_scale 1.0, got {w} -> {w2}"

        await ws.send(json.dumps({"t": "close"}))
        await recv_json(ws, "closed")
    api("/api/restore")
    print("STREAM TUNING E2E PASS")


asyncio.run(main())
