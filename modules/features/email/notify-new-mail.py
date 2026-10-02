"""Desktop notifications for new, unread mail (notmuch post-new hook).

Run by the post-new hook after the tag rules and before `new` is removed,
so `tag:new` is exactly what this `notmuch new` added, and spam/trash are
already tagged. One notification per message, or a single summary when
many arrive at once (e.g. the first sync after a while).
"""

import argparse
import html

import gi
import notmuch2

gi.require_version("Notify", "0.7")
from gi.repository import Notify  # noqa: E402

QUERY = "tag:new and tag:unread and not tag:spam and not tag:trash"
MAX_INDIVIDUAL = 5
APP = "notmuch"
ICON = "mail-unread"


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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default=QUERY, help="notmuch query (default: %(default)s)")
    parser.add_argument("--dry-run", action="store_true", help="print instead of notifying")
    args = parser.parse_args()

    with notmuch2.Database(mode=notmuch2.Database.MODE.READ_ONLY) as db:
        messages = sorted(
            ((m.date, sender(m), subject(m)) for m in db.messages(args.query)),
            key=lambda item: item[0],
        )

    if not messages:
        return

    if len(messages) > MAX_INDIVIDUAL:
        senders = sorted({s for _, s, _ in messages})
        shown = ", ".join(senders[:MAX_INDIVIDUAL])
        more = len(senders) - MAX_INDIVIDUAL
        notes = [
            (
                f"{len(messages)} new messages",
                "From " + shown + (f" and {more} more" if more > 0 else ""),
            )
        ]
    else:
        notes = [(s, subj) for _, s, subj in messages]

    if args.dry_run:
        for summary, body in notes:
            print(f"{summary}: {body}")
        return

    Notify.init(APP)
    for summary, body in notes:
        # The body is markup for most notification servers; summaries aren't.
        Notify.Notification.new(summary, html.escape(body), ICON).show()
    Notify.uninit()


if __name__ == "__main__":
    main()
