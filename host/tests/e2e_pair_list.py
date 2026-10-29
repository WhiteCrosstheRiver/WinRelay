"""E2E: pair a fake phone over the real WebSocket, then list windows.

Uses the loopback /api/status and /api/approve endpoints the way the
desktop UI does, so no human click is needed. Read-only afterwards:
we never open a window or send input.
"""
import asyncio
import json
import urllib.request

BASE = "http://localhost:47800"


def get_status():
    with urllib.request.urlopen(BASE + "/api/status", timeout=5) as r:
        return json.load(r)


def approve(device_id, allow):
    req = urllib.request.Request(
        BASE + "/api/approve",
        data=json.dumps({"id": device_id, "allow": allow}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        return r.status


async def main():
    status = get_status()
    link = status["link"]  # winrelay://pair?h=..&p=..&k=..&n=..
    q = dict(p.split("=", 1) for p in link.split("?", 1)[1].split("&"))
    token, port = q["k"], q["p"]
    ws_url = f"ws://localhost:{port}/ws"
    print("connecting", ws_url)

    import websockets

    device_id = "e2e-test-phone"
    async with websockets.connect(ws_url) as ws:
        await ws.send(json.dumps({
            "t": "hello", "device_id": device_id,
            "device_name": "E2E Test Phone", "token": token,
        }))
        msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
        assert msg["t"] == "pending", msg
        print("host says: pending (waiting for Approve)")

        code = approve(device_id, True)
        print("approved via /api/approve ->", code)

        msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
        assert msg["t"] == "approved", msg
        secret = msg["secret"]
        print("got secret, len =", len(secret))

        await ws.send(json.dumps({"t": "welcome-check"})) if False else None
        # after approval the host sends welcome; read until we see it
        while True:
            msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
            if msg["t"] == "welcome":
                print("welcome from", msg["host"])
                break

        await ws.send(json.dumps({"t": "list"}))
        while True:
            msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
            if msg["t"] == "windows":
                break
        print(f"windows: {len(msg['items'])} items")
        for it in msg["items"][:8]:
            print(f"  [{it['app']}] {it['title'][:60]}")

        # hidden-app check: re-hello with a wrong secret must be denied
    async with websockets.connect(ws_url) as ws:
        await ws.send(json.dumps({
            "t": "hello", "device_id": "intruder",
            "device_name": "Intruder", "secret": "wrong",
        }))
        msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
        assert msg["t"] == "denied", msg
        print("wrong secret correctly denied")

    # paired re-entry must succeed
    status2 = get_status()
    devs = [d for d in status2["devices"] if d["id"] == device_id]
    assert devs, "device should be saved in config"
    print("device saved:", devs[0]["name"])
    async with websockets.connect(ws_url) as ws:
        await ws.send(json.dumps({
            "t": "hello", "device_id": device_id,
            "device_name": "E2E Test Phone", "secret": secret,
        }))
        while True:
            msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
            if msg["t"] == "welcome":
                print("paired re-entry: welcome OK")
                break
        await ws.send(json.dumps({"t": "close"}))
    print("E2E PASS")


asyncio.run(main())
