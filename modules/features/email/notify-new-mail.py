"""Desktop notifications for new, unread mail (notmuch post-new hook).

Run by the post-new hook after the tag rules and before `new` is removed,
so `tag:new` is exactly what this `notmuch new` added, and spam/trash are
already tagged. One notification per message, or a single summary when
many arrive at once (e.g. the first sync after a while). Clicking one runs
`--open` with a notmuch query for its message(s), e.g. to show them in aerc.

The database is read before returning; a detached child then shows the
notifications and waits for clicks, so the hook (and mail-sync) carry on.
"""

import argparse
import html
import os
import subprocess
import sys

import gi
import notmuch2

gi.require_version("Notify", "0.7")
from gi.repository import GLib, Notify  # noqa: E402

QUERY = "tag:new and tag:unread and not tag:spam and not tag:trash"
MAX_INDIVIDUAL = 5
APP = "notmuch"
# How long the child waits for clicks (also from the notification history).
CLICK_WINDOW_SECONDS = 3600


def header(msg, name):
    # notmuch2 raises LookupError for a missing header instead of returning None.
    try:
        return msg.header(name)
    except LookupError:
        return ""


def sender(msg):
    # "Name <addr>" -> "Name"; a bare address stays as it is.
    raw = header(msg, "from") or "(unknown sender)"
    name = raw.split("<", 1)[0].strip().strip('"')
    return name or raw


def subject(msg):
    return header(msg, "subject") or "(no subject)"


def id_query(message_ids):
    # notmuch quotes with "..." and escapes a quote by doubling it.
    return " or ".join('id:"{}"'.format(i.replace('"', '""')) for i in message_ids)


def build_notes(messages):
    """(summary, body, query to open, open directly?) per notification: a
    message's own notification opens it, the summary lists its messages."""
    if len(messages) <= MAX_INDIVIDUAL:
        return [(s, subj, id_query([mid]), True) for _, mid, s, subj in messages]
    senders = sorted({s for _, _, s, _ in messages})
    more = len(senders) - MAX_INDIVIDUAL
    body = "From " + ", ".join(senders[:MAX_INDIVIDUAL]) + (f" and {more} more" if more > 0 else "")
    query = id_query([mid for _, mid, _, _ in messages])
    return [(f"{len(messages)} new messages", body, query, False)]


def detach():
    """Return in the parent; continue in a session-leader child with no
    inherited files (mail-sync's lock, the hook's stdout/stderr)."""
    if os.fork() > 0:
        os._exit(0)
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    os.closerange(3, os.sysconf("SC_OPEN_MAX"))


def notify(notes, icon, open_cmd):
    Notify.init(APP)
    loop = GLib.MainLoop()
    pending = []

    def on_open(_notification, _action, target):
        query, view = target
        if open_cmd:
            argv = [open_cmd] + (["--view"] if view else []) + [query]
            subprocess.Popen(argv, start_new_session=True)

    def on_closed(notification):
        pending.remove(notification)
        if not pending:
            loop.quit()

    for summary, body, query, view in notes:
        # The body is markup for most notification servers; summaries aren't.
        n = Notify.Notification.new(summary, html.escape(body), icon)
        if open_cmd:
            # "default" is the action for clicking the notification itself.
            n.add_action("default", "Open in aerc", on_open, (query, view))
        n.connect("closed", on_closed)
        pending.append(n)
        n.show()

    GLib.timeout_add_seconds(CLICK_WINDOW_SECONDS, loop.quit)
    loop.run()
    Notify.uninit()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default=QUERY, help="notmuch query (default: %(default)s)")
    parser.add_argument("--icon", default="mail-unread", help="icon name or file path")
    parser.add_argument("--open", dest="open_cmd", help="command run with a notmuch query on click")
    parser.add_argument("--dry-run", action="store_true", help="print instead of notifying")
    parser.add_argument("--foreground", action="store_true", help="don't detach (for testing)")
    args = parser.parse_args()

    with notmuch2.Database(mode=notmuch2.Database.MODE.READ_ONLY) as db:
        messages = sorted(
            (
                (m.date, m.messageid, sender(m), subject(m))
                for m in db.messages(args.query)
            ),
            key=lambda item: item[0],
        )

    if not messages:
        return
    notes = build_notes(messages)

    if args.dry_run:
        for summary, body, query, view in notes:
            print(f"{summary}: {body}\n  open: {'--view ' if view else ''}{query}")
        return

    if not args.foreground:
        sys.stdout.flush()
        detach()
    notify(notes, args.icon, args.open_cmd)


if __name__ == "__main__":
    main()
