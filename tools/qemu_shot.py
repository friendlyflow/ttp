#!/usr/bin/env python3
"""Boot the ttp image in QEMU, optionally send keys, grab a VGA screendump.

Usage: qemu_shot.py <img> <out.png> [boot_seconds] [keys]
  keys: space-separated QEMU sendkey names, e.g. "down down right ret"
Talks to the QEMU HMP monitor over a unix socket; needs no display.
"""
import os, socket, subprocess, sys, time
from PIL import Image

img = sys.argv[1]
out = sys.argv[2]
boot_s = float(sys.argv[3]) if len(sys.argv) > 3 else 2.5
keys = sys.argv[4].split() if len(sys.argv) > 4 and sys.argv[4] else []
sock_path = "/tmp/ttp_qmon.sock"
ppm = "/tmp/ttp_screen.ppm"

for p in (sock_path, ppm, out):
    try: os.remove(p)
    except FileNotFoundError: pass

qemu = subprocess.Popen([
    "qemu-system-x86_64",
    "-drive", f"format=raw,file={img}",
    "-display", "none",
    "-monitor", f"unix:{sock_path},server,nowait",
    "-no-reboot", "-no-shutdown",
])
try:
    # wait for the monitor socket
    for _ in range(100):
        if os.path.exists(sock_path):
            break
        time.sleep(0.05)
    time.sleep(boot_s)  # let the kernel boot and render

    s = socket.socket(socket.AF_UNIX)
    s.connect(sock_path)
    time.sleep(0.2)
    s.recv(4096)  # greeting
    for k in keys:
        s.sendall(f"sendkey {k}\n".encode())
        time.sleep(0.15)
        try: s.recv(4096)
        except Exception: pass
    time.sleep(0.3)
    s.sendall(f"screendump {ppm}\n".encode())
    time.sleep(0.6)
    try: s.recv(4096)
    except Exception: pass
    s.close()
finally:
    qemu.terminate()
    try: qemu.wait(timeout=3)
    except Exception: qemu.kill()

if not os.path.exists(ppm):
    print("ERROR: no screendump produced", file=sys.stderr)
    sys.exit(1)
Image.open(ppm).save(out)
print(f"saved {out}")
