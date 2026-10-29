"""Verify the WS listener answers on the global IPv6 address itself.

Connecting to the PC's own public v6 address proves the dual-stack socket
accepts that path (the phone will come in exactly this way). We use a wrong
secret on purpose: a TCP+WS connect that ends in a JSON `denied` is a pass.
"""
import asyncio
import json
import urllib.request

import websockets

status = json.load(urllib.request.urlopen("http://localhost:47800/api/status", timeout=5))
v6 = next(a["ip"] for a in status["addresses"] if a["kind"].startswith("Internet"))
url = f"ws://[{v6}]:47800/ws"
print("connecting", url)


async def main():
    async with websockets.connect(url, open_timeout=10) as ws:
        await ws.send(json.dumps({"t": "hello", "device_id": "v6-check", "device_name": "v6 check", "secret": "nope"}))
        msg = json.loads(await asyncio.wait_for(ws.recv(), 10))
        assert msg["t"] == "denied", msg
        print("public IPv6 ingress: TCP+WS OK, auth correctly denied ->", msg["reason"][:40], "…")


asyncio.run(main())
print("V6 INGRESS PASS")
