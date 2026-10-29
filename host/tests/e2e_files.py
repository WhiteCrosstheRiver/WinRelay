"""E2E: phone-side file access — list drives, browse, mkdir, upload, download,
delete (Recycle Bin). Runs against the real host over the real WebSocket.
"""
import asyncio
import json
import os
import struct
import urllib.request

import websockets

BASE = "http://localhost:47800"
FS_HEADER = 25
CHUNK = 256 * 1024
TEST_DIR = os.path.join(os.environ["TEMP"], "winrelay-fs-e2e")


def api(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"}, method="POST")
    return urllib.request.urlopen(req, timeout=5).status


async def recv_json(ws, want_t, timeout=20):
    while True:
        raw = await asyncio.wait_for(ws.recv(), timeout)
        if isinstance(raw, (bytes, bytearray)):
            continue
        msg = json.loads(raw)
        if msg.get("t") == want_t:
            return msg


async def main():
    st = json.load(urllib.request.urlopen(BASE + "/api/status", timeout=5))
    dev = next(d for d in st["devices"] if d["name"] == "My phone")
    cfg = json.load(open(os.path.join(os.environ["APPDATA"], "WinRelay", "config.json"), encoding="utf-8"))
    secret = next(d["secret"] for d in cfg["devices"] if d["id"] == dev["id"])

    async with websockets.connect(f"ws://localhost:{st['port']}/ws") as ws:
        await ws.send(json.dumps({"t": "hello", "device_id": dev["id"], "device_name": "e2e", "secret": secret}))
        await recv_json(ws, "welcome")

        # 1. drive root
        await ws.send(json.dumps({"t": "fs_list", "path": ""}))
        drives = (await recv_json(ws, "fs_entries"))["items"]
        print("drives:", [d["name"] for d in drives])
        assert any(d["name"] == "C:" for d in drives)

        # 2. browse into test dir
        os.makedirs(TEST_DIR, exist_ok=True)
        await ws.send(json.dumps({"t": "fs_list", "path": TEST_DIR}))
        entries = (await recv_json(ws, "fs_entries"))["items"]
        print("test dir is empty:", len(entries) == 0)

        # 3. mkdir
        sub = os.path.join(TEST_DIR, "from-phone")
        await ws.send(json.dumps({"t": "fs_mkdir", "path": sub}))
        done = await recv_json(ws, "fs_done")
        assert done["ok"], done
        assert os.path.isdir(sub), "folder not created"

        # 4. upload 1 MiB of random data in chunks
        up_id, payload = 11, os.urandom(1024 * 1024)
        up_path = os.path.join(TEST_DIR, "uploaded.bin")
        await ws.send(json.dumps({"t": "fs_upload_begin", "id": up_id, "path": up_path, "size": len(payload)}))
        await recv_json(ws, "fs_upload_ready")
        off = 0
        while off < len(payload):
            chunk = payload[off : off + CHUNK]
            frame = struct.pack("<BQQQ", 4, up_id, off, len(payload)) + chunk
            await ws.send(frame)
            off += len(chunk)
        await ws.send(json.dumps({"t": "fs_upload_end", "id": up_id}))
        done = await recv_json(ws, "fs_done")
        assert done["ok"], done
        with open(up_path, "rb") as f:
            assert f.read() == payload, "uploaded content mismatch"
        print("upload: 1 MiB verified byte-for-byte")

        # 5. download it back
        dl_id, buf = 22, {}
        dl_size = None
        await ws.send(json.dumps({"t": "fs_download", "id": dl_id, "path": up_path}))
        meta = await recv_json(ws, "fs_meta")
        dl_size = meta["size"]
        while True:
            raw = await asyncio.wait_for(ws.recv(), 20)
            if isinstance(raw, (bytes, bytearray)):
                kind, fid, offset, total = struct.unpack("<BQQQ", raw[:25])
                assert kind == 3 and fid == dl_id
                buf[offset] = raw[25:]
                continue
            msg = json.loads(raw)
            if msg.get("t") == "fs_done":
                assert msg["ok"], msg
                break
        blob = b"".join(buf[o] for o in sorted(buf))
        assert len(blob) == dl_size and blob == payload, "roundtrip mismatch"
        print(f"download: {dl_size} bytes roundtrip verified, {len(buf)} chunks")

        # 6. upload another file, then delete both via Recycle Bin
        small = os.path.join(TEST_DIR, "small.txt")
        with open(small, "w", encoding="utf-8") as f:
            f.write("hello winrelay")
        await ws.send(json.dumps({"t": "fs_upload_begin", "id": 33, "path": os.path.join(TEST_DIR, "note.txt"), "size": 14}))
        await recv_json(ws, "fs_upload_ready")
        frame = struct.pack("<BQQQ", 4, 33, 0, 14) + b"hello winrelay"
        await ws.send(frame)
        await ws.send(json.dumps({"t": "fs_upload_end", "id": 33}))
        done = await recv_json(ws, "fs_done")
        assert done["ok"]

        for victim in (up_path, os.path.join(TEST_DIR, "note.txt")):
            await ws.send(json.dumps({"t": "fs_delete", "path": victim}))
            done = await recv_json(ws, "fs_done")
            assert done["ok"], done
            assert not os.path.exists(victim), "file still there"
        print("delete: files moved out of the folder (Recycle Bin)")

        await ws.send(json.dumps({"t": "fs_list", "path": TEST_DIR}))
        left = (await recv_json(ws, "fs_entries"))["items"]
        names = sorted(e["name"] for e in left)
        print("remaining:", names)
        assert "uploaded.bin" not in names and "note.txt" not in names, names
        assert "from-phone" in names, names

    api("/api/restore")
    print("FILES E2E PASS")


asyncio.run(main())
