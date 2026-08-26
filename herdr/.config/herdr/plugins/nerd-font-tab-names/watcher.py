#!/usr/bin/env python3
"""Prefix herdr tab labels with a nerd font icon for the running process.

The herdr port of joshmedeski/tmux-nerd-font-window-name. herdr has no config
for tab label formatting, so this renames tabs over the socket API instead.

Manual names win: the icon is prefixed to whatever label the tab already has,
and only tabs still showing their bare number get "<icon> <process>".

Socket notes: the API socket serves one request per connection, so every call
opens its own connection. Event subscriptions are the exception -- they hold the
connection open and stream pushed lines.
"""

import json
import os
import re
import select
import signal
import socket
import sys
import time

PLUGIN_DIR = os.path.dirname(os.path.abspath(__file__))
SOCKET_PATH = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser(
    "~/.config/herdr/herdr.sock"
)
# herdr sets HERDR_PLUGIN_STATE_DIR when it runs an action; fall back to the same
# path (not the plugin dir) so `watcher.py status|stop` run by hand from a shell
# find the worker herdr started, and no runtime files land in the dotfiles repo.
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser(
    "~/.local/state/herdr/plugins/nerd-font-tab-names"
)
CONFIG_DIR = os.environ.get("HERDR_PLUGIN_CONFIG_DIR", "")
PIDFILE = os.path.join(STATE_DIR, "watcher.pid")
STATEFILE = os.path.join(STATE_DIR, "labels.json")

SWEEP_SECONDS = 5.0
DEBOUNCE_SECONDS = 0.15

# A process change that alters no terminal title emits no event, hence the sweep.
SUBSCRIPTIONS = [
    "pane.updated",
    "pane.created",
    "pane.focused",
    "pane.exited",
    "tab.created",
    "tab.focused",
]


# ─── Icons ────────────────────────────────────────────────────────────────

def load_icons():
    """Parse the flat two-level icons.yml. No yaml dependency by design."""
    cfg, icons = {}, {}
    paths = [os.path.join(PLUGIN_DIR, "icons.yml")]
    if CONFIG_DIR:
        paths.append(os.path.join(CONFIG_DIR, "icons.yml"))  # user override
    for path in paths:
        if not os.path.exists(path):
            continue
        section = None
        for line in open(path, encoding="utf-8"):
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if not line.startswith(" "):
                section = line.split(":")[0].strip()
                continue
            m = re.match(r"\s+([^:]+):\s*(.*)$", line.rstrip("\n"))
            if not m:
                continue
            key, value = m.group(1).strip(), m.group(2).strip().strip("\"'")
            (cfg if section == "config" else icons)[key] = value
    return cfg, icons


CONFIG, ICONS = load_icons()
FALLBACK = CONFIG.get("fallback-icon", "?")
GLYPHS = set(ICONS.values()) | {FALLBACK}


# ─── Socket ───────────────────────────────────────────────────────────────

def request(method, params=None, timeout=5.0):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect(SOCKET_PATH)
        stream = sock.makefile("rwb")
        stream.write(
            (json.dumps({"id": "tabnamer", "method": method, "params": params or {}}) + "\n").encode()
        )
        stream.flush()
        return json.loads(stream.readline() or "{}")
    finally:
        sock.close()


# ─── Naming ───────────────────────────────────────────────────────────────

def process_name(pane_id):
    reply = request("pane.process_info", {"pane_id": pane_id})
    procs = reply.get("result", {}).get("process_info", {}).get("foreground_processes", [])
    # Last entry is the leaf: [node, node, claude] -> claude.
    return procs[-1].get("name") if procs else None


def strip_icon(label):
    if len(label) > 1 and label[0] in GLYPHS and label[1] == " ":
        return label[2:]
    return label


def target_label(current, process, was_auto):
    """Icon + label. `was_auto` means we generated the whole label last time, so
    its base is a stale process name rather than something the user typed."""
    icon = ICONS.get(process, FALLBACK)
    base = strip_icon(current).strip()
    if was_auto or not base or base.isdigit():
        base = process  # unnamed tab: mirror tmux and use the process name
    return f"{icon} {base}", base == process


def plan(state=None):
    """Return [(tab_id, current_label, new_label, auto)] for tabs needing a rename."""
    state = state if state is not None else {}
    snapshot = request("session.snapshot").get("result", {}).get("snapshot", {})
    panes = snapshot.get("panes", [])
    changes = []
    for tab in snapshot.get("tabs", []):
        tab_id = tab.get("tab_id")
        tab_panes = [p for p in panes if p.get("tab_id") == tab_id]
        if not tab_panes:
            continue
        pane = next((p for p in tab_panes if p.get("focused")), tab_panes[0])
        process = process_name(pane["pane_id"])
        if not process:
            continue
        current = tab.get("label", "")
        known = state.get(tab_id) or {}
        # Only trust the auto flag while the label is still the one we wrote; if
        # the user renamed the tab since, that name is theirs to keep.
        was_auto = bool(known.get("auto")) and known.get("label") == current
        new, auto = target_label(current, process, was_auto)
        if new != current:
            changes.append((tab_id, current, new, auto))
    return changes


def apply_changes(dry_run=False):
    state = read_state()
    for tab_id, current, new, auto in plan(state):
        if dry_run:
            print(f"{tab_id}: {current!r} -> {new!r}")
            continue
        reply = request("tab.rename", {"tab_id": tab_id, "label": new})
        if "error" in reply:
            log(f"rename {tab_id} failed: {reply['error']}")
        else:
            state[tab_id] = {"label": new, "auto": auto}
    if not dry_run:
        write_state(state)


# ─── State ────────────────────────────────────────────────────────────────

def read_state():
    try:
        return json.load(open(STATEFILE, encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def write_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    tmp = STATEFILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(state, fh)
    os.replace(tmp, STATEFILE)


def log(message):
    print(f"[nerd-font-tab-names] {message}", flush=True)


# ─── Worker ───────────────────────────────────────────────────────────────

def run():
    log(f"watching {SOCKET_PATH} ({len(ICONS)} icons)")
    while True:
        try:
            watch_once()
        except (OSError, ValueError) as exc:
            log(f"stream error: {exc}; retrying in 2s")
            time.sleep(2.0)


def watch_once():
    """Hold one subscription connection; rename on events and on the sweep.

    Raw recv + select rather than makefile(): a socket timeout permanently
    poisons a buffered file object ("cannot read from timed out object"), so the
    stream cannot be reused after a quiet period.
    """
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(5.0)
    sock.connect(SOCKET_PATH)
    sock.sendall(
        (
            json.dumps(
                {
                    "id": "tabnamer-sub",
                    "method": "events.subscribe",
                    "params": {"subscriptions": [{"type": t} for t in SUBSCRIPTIONS]},
                }
            )
            + "\n"
        ).encode()
    )

    try:
        buf = b""
        while b"\n" not in buf:
            chunk = sock.recv(65536)
            if not chunk:
                raise OSError("closed before subscription ack")
            buf += chunk
        ack_line, buf = buf.split(b"\n", 1)
        ack = json.loads(ack_line or b"{}")
        if "error" in ack:
            raise ValueError(f"subscribe rejected: {ack['error']}")
        log("subscribed")

        sock.setblocking(True)
        sock.settimeout(None)
        apply_changes()
        last_sweep = time.monotonic()

        while True:
            ready, _, _ = select.select([sock], [], [], SWEEP_SECONDS)
            saw_event = False
            if ready:
                buf, lines = read_lines(sock, buf)
                saw_event = bool(lines)
                if saw_event:
                    time.sleep(DEBOUNCE_SECONDS)  # coalesce bursts
                    while select.select([sock], [], [], 0)[0]:
                        buf, _ = read_lines(sock, buf)

            if saw_event or time.monotonic() - last_sweep >= SWEEP_SECONDS:
                apply_changes()
                last_sweep = time.monotonic()
    finally:
        sock.close()


def read_lines(sock, buf):
    """Append one recv to buf and return (remainder, complete lines)."""
    chunk = sock.recv(65536)
    if not chunk:
        raise OSError("event stream closed")
    buf += chunk
    *lines, remainder = buf.split(b"\n")
    return remainder, [l for l in lines if l.strip()]


# ─── Lifecycle ────────────────────────────────────────────────────────────

def worker_pid():
    try:
        pid = int(open(PIDFILE, encoding="utf-8").read().strip())
    except (OSError, ValueError):
        return None
    try:
        os.kill(pid, 0)
    except OSError:
        return None
    return pid


def start():
    pid = worker_pid()
    if pid:
        print(f"already running (pid {pid})")
        return 0
    os.makedirs(STATE_DIR, exist_ok=True)
    # Double fork so the worker outlives the invoking action.
    if os.fork() != 0:
        time.sleep(0.3)
        pid = worker_pid()
        print(f"started (pid {pid})" if pid else "failed to start")
        return 0 if pid else 1
    os.setsid()
    if os.fork() != 0:
        os._exit(0)
    logfile = os.path.join(STATE_DIR, "watcher.log")
    with open(os.devnull) as devnull, open(logfile, "a", buffering=1) as out:
        os.dup2(devnull.fileno(), 0)
        os.dup2(out.fileno(), 1)
        os.dup2(out.fileno(), 2)
        with open(PIDFILE, "w", encoding="utf-8") as fh:
            fh.write(str(os.getpid()))
        try:
            run()
        finally:
            try:
                os.unlink(PIDFILE)
            except OSError:
                pass
    os._exit(0)


def stop():
    pid = worker_pid()
    if not pid:
        print("not running")
        return 0
    os.kill(pid, signal.SIGTERM)
    print(f"stopped (pid {pid})")
    return 0


def status():
    pid = worker_pid()
    print(f"running (pid {pid})" if pid else "not running")
    return 0


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "once":
        changes = plan(read_state())
        for tab_id, current, new, _auto in changes:
            print(f"{tab_id}: {current!r} -> {new!r}")
        if not changes:
            print("no changes")
        return 0
    if command == "apply":
        apply_changes()
        return 0
    if command == "run":
        run()
        return 0
    if command == "start":
        return start()
    if command == "stop":
        return stop()
    if command == "status":
        return status()
    print(f"unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
