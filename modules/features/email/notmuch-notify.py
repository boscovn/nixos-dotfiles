"""New-mail notification daemon (notify.nix).

Socket-activated by systemd (notmuch-notify.socket). notmuch's post-new hook
(notmuch-notify-send) connects, writes one JSON array per batch of new mail,

    [{"id": "<message-id>", "date": 1791008343, "from": "...", "subject": "..."}]

and closes. One notification per message, or a single summary above
MAX_INDIVIDUAL (e.g. the first sync after a while). Clicking one runs
`--open` (mail-open) with a notmuch query for its message(s). Every
notification is kept until it's closed, so clicks work for as long as the
daemon runs, also from the notification history. No notmuch dependency: the
hook sends what's shown.
"""

import argparse
import html
import json
import os
import re
import socket
import subprocess
import sys

import gi

gi.require_version("Notify", "0.7")
from gi.repository import GLib, Notify  # noqa: E402

APP = "notmuch"
MAX_INDIVIDUAL = 5
SD_LISTEN_FDS_START = 3
# Zero-width and bidi control characters, used by some senders to dodge filters.
INVISIBLE = re.compile("[​-‏‪-‮⁠-⁤﻿]")


def log(*args):
    print(*args, file=sys.stderr, flush=True)


def sender(raw):
    # '"Name" <addr>' -> 'Name'; a bare address stays as it is.
    raw = INVISIBLE.sub("", raw or "").strip()
    name = raw.split("<", 1)[0].strip().strip('"').strip()
    return name or raw or "(unknown sender)"


def subject(raw):
    return INVISIBLE.sub("", raw or "").strip() or "(no subject)"


def id_query(message_ids):
    # notmuch quotes with "..." and escapes a quote by doubling it.
    return " or ".join('id:"{}"'.format(i.replace('"', '""')) for i in message_ids)


def build_notes(batch):
    """(summary, body, query to open, open directly?) per notification: a
    message's own notification opens it, the summary lists its messages."""
    messages = sorted(
        (m for m in batch if isinstance(m, dict) and m.get("id")),
        key=lambda m: m.get("date") or 0,
    )
    if not messages:
        return []
    if len(messages) <= MAX_INDIVIDUAL:
        return [(sender(m.get("from")), subject(m.get("subject")), id_query([m["id"]]), True) for m in messages]
    senders = sorted({sender(m.get("from")) for m in messages})
    more = len(senders) - MAX_INDIVIDUAL
    body = "From " + ", ".join(senders[:MAX_INDIVIDUAL]) + (f" and {more} more" if more > 0 else "")
    return [(f"{len(messages)} new messages", body, id_query([m["id"] for m in messages]), False)]


def listening_socket(path):
    """systemd's socket when activated (LISTEN_FDS), else bind `path` (testing)."""
    if os.environ.get("LISTEN_PID") == str(os.getpid()) and int(os.environ.get("LISTEN_FDS", "0")) >= 1:
        return socket.socket(fileno=SD_LISTEN_FDS_START)
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.bind(path)
    os.chmod(path, 0o600)
    sock.listen()
    return sock


class Daemon:
    def __init__(self, icon, open_cmd, print_only):
        self.icon = icon
        self.open_cmd = open_cmd
        self.print_only = print_only
        # Notifications stay referenced (and their click handlers alive) until
        # the notification server reports them closed.
        self.live = set()

    def on_open(self, _notification, _action, target):
        query, view = target
        if self.open_cmd:
            argv = [self.open_cmd] + (["--view"] if view else []) + [query]
            subprocess.Popen(argv, start_new_session=True)

    def on_closed(self, notification):
        self.live.discard(notification)

    def show(self, notes):
        for summary, body, query, view in notes:
            if self.print_only:
                print(f"{summary}: {body}\n  open: {'--view ' if view else ''}{query}", flush=True)
                continue
            # The body is markup for most notification servers; summaries aren't.
            n = Notify.Notification.new(summary, html.escape(body), self.icon)
            if self.open_cmd:
                # "default" is the action for clicking the notification itself.
                n.add_action("default", "Open in aerc", self.on_open, (query, view))
            n.connect("closed", self.on_closed)
            self.live.add(n)
            n.show()

    def on_connection(self, sock, _condition):
        # Any error stays in this batch: a GLib watch whose callback raises is
        # removed, and the daemon would silently stop accepting batches.
        try:
            conn, _ = sock.accept()
            with conn:
                conn.settimeout(5)
                data = b""
                while chunk := conn.recv(65536):
                    data += chunk
            self.show(build_notes(json.loads(data or b"[]")))
        except (OSError, ValueError) as err:
            log("bad batch:", err)
        except Exception as err:  # e.g. GLib.Error: notification server unreachable
            log("couldn't notify:", err)
        return True  # keep watching


def main():
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--socket", default=f"{runtime}/notmuch-notify.sock", help="when not socket-activated")
    parser.add_argument("--icon", default="mail-unread", help="icon name or file path")
    parser.add_argument("--open", dest="open_cmd", help="command run with a notmuch query on click")
    parser.add_argument("--print", dest="print_only", action="store_true", help="print instead of notifying")
    args = parser.parse_args()

    sock = listening_socket(args.socket)
    daemon = Daemon(args.icon, args.open_cmd, args.print_only)
    if not args.print_only:
        Notify.init(APP)
    GLib.io_add_watch(sock.fileno(), GLib.IO_IN, lambda _fd, cond: daemon.on_connection(sock, cond))
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
