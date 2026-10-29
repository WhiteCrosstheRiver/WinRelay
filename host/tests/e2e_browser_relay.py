"""E2E: browser relay — open a real browser window, receive its URL, push a
navigation back, and confirm the browser actually went there.

Uses the first Edge/Chrome/Firefox window found. The window is moved for the
session and restored after; the browser is navigated back to its original
page before we finish. Reads/writes the browser's address bar via Ctrl+L /
Ctrl+C (clipboard is restored).
"""
import asyncio
import json
import os
import struct
import urllib.request

import websockets

BASE = "http://localhost:47800"
TEST_URL = "https://example.com/"
VIEWPORT = {"w": 400, "h": 800, "dpr": 2}
BROWSERS = {"msedge.exe", "chrome.exe", "firefox.exe", "brave.exe", "vivaldi.exe", "opera.exe"}


def status():
    return json.load(urllib.request.urlopen(BASE + "/api/status", timeout=5))


def api(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"}, method="POST")
    return urllib.request.urlopen(req, timeout=5).status


async def recv(ws, want_t, timeout=20):
    while True:
        raw = await asyncio.wait_for(ws.recv(), timeout)
        if isinstance(raw, (bytes, bytearray)):
            continue
        msg = json.loads(raw)
        if msg.get("t") == want_t:
            return msg


async def main():
    st = status()
    dev = next(d for d in st["devices"] if d["name"] == "My phone")
    cfg = json.load(open(os.path.join(os.environ["APPDATA"], "WinRelay", "config.json"), encoding="utf-8"))
    secret = next(d["secret"] for d in cfg["devices"] if d["id"] == dev["id"])

    async with websockets.connect(f"ws://localhost:{st['port']}/ws") as ws:
        await ws.send(json.dumps({"t": "hello", "device_id": dev["id"], "device_name": "e2e", "secret": secret}))
        await recv(ws, "welcome")
        await ws.send(json.dumps({"t": "list"}))
        wins = (await recv(ws, "windows"))["items"]
        browsers = [w for w in wins if w["exe"].lower() in BROWSERS]
        assert browsers, "no browser window open to test with"
        target = browsers[0]
        print("browser window:", target["title"][:60], "|", target["exe"])

        await ws.send(json.dumps({"t": "open", "id": target["id"], "stealth": False,
                                  "viewport": VIEWPORT, "scale": 1.0}))
        opened = await recv(ws, "opened")
        print("opened:", opened["title"][:50])

        # host should push the page URL on its own
        url_msg = await recv(ws, "url")
        original = url_msg["url"]
        print("current URL:", original[:90])

        # phone pushes a navigation; the browser must actually go there
        await ws.send(json.dumps({"t": "navigate", "url": TEST_URL}))
        await asyncio.sleep(4)
        await ws.send(json.dumps({"t": "get_url"}))
        again = (await recv(ws, "url"))["url"]
        print("after navigate:", again[:90])
        assert again.lower().startswith(TEST_URL.lower()), f"navigation failed: {again}"

        # put the browser back where it was
        await ws.send(json.dumps({"t": "navigate", "url": original}))
        await asyncio.sleep(3)
        await ws.send(json.dumps({"t": "close"}))
        await recv(ws, "closed")
    api("/api/restore")
    print("BROWSER RELAY E2E PASS")


asyncio.run(main())
