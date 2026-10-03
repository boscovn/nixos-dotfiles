"""New-mail notification daemon (notify.nix).

Socket-activated by systemd (notmuch-notify.socket). notmuch's post-new hook
(notmuch-notify-send) connects, writes one JSON array per batch of new mail,

    [{"id": "<message-id>", "date": 1791008343, "from": "...", "subject": "...",
      "text": "<body, truncated>", "html": false}]

and closes. One notification per message, or a single summary above
MAX_INDIVIDUAL (e.g. the first sync after a while). Clicking one runs
`--open` (mail-open) with a notmuch query for its message(s). Every
notification is kept until it's closed, so clicks work for as long as the
daemon runs, also from the notification history. No notmuch dependency: the
hook sends what's shown.

A message's notification with a one-time code (verification, login, reset
codes; one_time_code) shows it and has a "Copy <code>" button, which pipes it
to `--copy` (wl-copy --sensitive); it is closed after CODE_LIFETIME. The body
text is only used for that, and isn't kept.
"""

import argparse
import html
import json
import os
import re
import socket
import subprocess
import sys
from html.parser import HTMLParser

import gi

gi.require_version("Notify", "0.7")
from gi.repository import GLib, Notify  # noqa: E402

APP = "notmuch"
MAX_INDIVIDUAL = 5
CODE_LIFETIME = 10 * 60  # seconds a notification with a one-time code stays
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


class _Text(HTMLParser):
    """Visible text of an HTML body (no <style>/<script>/<head>)."""

    SKIP = {"style", "script", "head", "title"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skipping = 0

    def handle_starttag(self, tag, _attrs):
        if tag in self.SKIP:
            self.skipping += 1
        elif tag in ("br", "p", "div", "tr", "td", "li", "h1", "h2", "h3"):
            self.out.append("\n")

    def handle_endtag(self, tag):
        if tag in self.SKIP and self.skipping:
            self.skipping -= 1

    def handle_data(self, data):
        if not self.skipping:
            self.out.append(data)


def visible_text(text, is_html):
    if not is_html:
        return text or ""
    parser = _Text()
    try:
        parser.feed(text or "")
    except Exception:  # malformed HTML: whatever was parsed so far
        pass
    return "".join(parser.out)


# One-time codes: 4-8 digits (or 3+3 split by a space or dash), a short
# letter prefix like G-123456, or 5-10 letters and digits mixed (Proton's
# NBX37Y5EXR, Namecheap's f60870). Only taken near a keyword, in the subject
# or shortly before the code, as codes look like many other numbers.
KEYWORDS = re.compile(
    r"c[oó]digo(?! postal| secuencial)|(?<!zip )(?<!post )(?<!postal )\bcodes?\b"
    r"|verificaci[oó]n|verification|verify|one[- ]time|\botp\b|\b2fa\b"
    r"|two[- ]factor|\bpin\b|passcode|security|seguridad|un solo uso|clave"
    r"|token|login|log in|sign[- ]in|inicio de sesi[oó]n|activaci[oó]n|activation",
    re.I,
)
# Not part of a longer number ("123 653 461 9"), a link, an amount, a
# bracketed reference or an expression.
CODE = re.compile(
    r"(?<![\w.,:/@#+(*=-])(?<!\d[ -])((?:[A-Z]{1,3}-)?\d{4,8}|\d{3}[ -]\d{3}|[A-Za-z0-9]{5,10})"
    r"(?![\w.,:/@%)*=-]|[ -]\d| ?[*+/=])"
)
# Number shapes that aren't codes, next to the candidate.
CURRENCY = re.compile(r"[€$£¥]|\b(?:eur|usd|gbp)\b", re.I)
NUMBERED = re.compile(r"(?:\bN[º°o]\.?|#) ?$")  # Nº 2737: a registration number
# Online meetings' passcodes (Teams' "Código de acceso: 53rh93pb").
MEETING = re.compile(r"meeting|reuni[oó]n|conference|webinar", re.I)
STREET = re.compile(r" (?:[NSEW]\.? )?(?:[A-Z][\w.]* ){1,3}(?:Ave|Avenue|St|Street|Rd|Road|Blvd|Suite|Way|Dr|Drive)\b")
NEAR_KEYWORD = 80  # characters between a keyword and the code


def plausible(code, text, start, end):
    if code.isdigit():
        if len(code) > 8:
            return False  # phone, account or order numbers
    elif re.fullmatch(r"[A-Za-z0-9]+", code):
        # Letters and digits: needs both, in one case (mixed case is meeting
        # passcodes, ids), and not a word with a number on either end
        # (usernames, device models: boscovn96, CPH2307).
        if not (re.search(r"\d", code) and re.search(r"[A-Za-z]", code)):
            return False
        if code != code.upper() and code != code.lower():
            return False
        if re.fullmatch(r"[A-Za-z]{2,}\d+|\d+[A-Za-z]{2,}", code):
            return False
    digits = re.sub(r"\D", "", code)
    if len(digits) == 4 and re.fullmatch(r"(19|20)\d\d", digits):
        return False  # a year
    around = text[max(0, start - 3) : end + 4]
    if CURRENCY.search(around):
        return False  # an amount
    if STREET.match(text, end):
        return False  # a street number in a footer address
    if NUMBERED.search(text[max(0, start - 4) : start]):
        return False
    return True


def one_time_code(subject, text):
    """The most likely one-time code in a message, or None."""
    subject = subject or ""
    # Subject first: "123456 is your Reddit verification code".
    if KEYWORDS.search(subject):
        for m in CODE.finditer(subject):
            if plausible(m.group(1), subject, m.start(1), m.end(1)):
                return m.group(1)
    body = INVISIBLE.sub("", text or "")
    # Links and addresses carry tracking ids and usernames, never the code.
    body = re.sub(r"\S*(?:https?://|www\.|@)\S*", " ", body)
    body = re.sub(r"[ \t\u00a0]+", " ", body)
    keyword_in_subject = bool(KEYWORDS.search(subject))
    for m in CODE.finditer(body):
        start, end = m.start(1), m.end(1)
        if not plausible(m.group(1), body, start, end):
            continue
        before = body[max(0, start - NEAR_KEYWORD) : start]
        keywords = list(KEYWORDS.finditer(before))
        # The keyword's sentence: "...security. Coinbase · Oakland, CA 94607"
        # is an address after the end of it.
        if (
            keywords
            and not re.search(r"[.!?](?:\s|$)", before[keywords[-1].end() :])
            and not MEETING.search(before)
        ):
            return m.group(1)
        # A code-ish subject and the number standing on its own line.
        line = body[body.rfind("\n", 0, start) + 1 : (body.find("\n", end) + 1 or len(body) + 1) - 1]
        if keyword_in_subject and line.strip() == m.group(1):
            return m.group(1)
    return None


def id_query(message_ids):
    # notmuch quotes with "..." and escapes a quote by doubling it.
    return " or ".join('id:"{}"'.format(i.replace('"', '""')) for i in message_ids)


def build_notes(batch):
    """(summary, body, query to open, open directly?, one-time code or None)
    per notification: a message's own notification opens it (and offers to
    copy its code), the summary lists its messages."""
    messages = sorted(
        (m for m in batch if isinstance(m, dict) and m.get("id")),
        key=lambda m: m.get("date") or 0,
    )
    if not messages:
        return []
    if len(messages) <= MAX_INDIVIDUAL:
        notes = []
        for m in messages:
            code = one_time_code(m.get("subject"), visible_text(m.get("text"), m.get("html")))
            body = subject(m.get("subject")) + (f"\nCode: {code}" if code else "")
            notes.append((sender(m.get("from")), body, id_query([m["id"]]), True, code))
        return notes
    senders = sorted({sender(m.get("from")) for m in messages})
    more = len(senders) - MAX_INDIVIDUAL
    body = "From " + ", ".join(senders[:MAX_INDIVIDUAL]) + (f" and {more} more" if more > 0 else "")
    return [(f"{len(messages)} new messages", body, id_query([m["id"] for m in messages]), False, None)]


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
    def __init__(self, icon, open_cmd, copy_cmd, print_only):
        self.icon = icon
        self.open_cmd = open_cmd
        self.copy_cmd = copy_cmd
        self.print_only = print_only
        # Notifications stay referenced (and their click handlers alive) until
        # the notification server reports them closed.
        self.live = set()

    def on_open(self, _notification, _action, target):
        query, view = target
        if self.open_cmd:
            argv = [self.open_cmd] + (["--view"] if view else []) + [query]
            subprocess.Popen(argv, start_new_session=True)

    def on_copy(self, _notification, _action, code):
        # The code is the command's stdin, not an argument (visible in ps).
        subprocess.run([self.copy_cmd], input=code.encode(), start_new_session=True)

    def on_closed(self, notification):
        self.live.discard(notification)

    def expire(self, notification):
        # Also drops it from the notification history: codes go stale, and
        # needn't stay on screen.
        if notification in self.live:
            try:
                notification.close()
            except GLib.Error:
                pass
        return False  # once

    def show(self, notes):
        for summary, body, query, view, code in notes:
            if self.print_only:
                print(f"{summary}: {body}\n  open: {'--view ' if view else ''}{query}", flush=True)
                continue
            # The body is markup for most notification servers; summaries aren't.
            n = Notify.Notification.new(summary, html.escape(body), self.icon)
            if self.open_cmd:
                # "default" is the action for clicking the notification itself.
                n.add_action("default", "Open in aerc", self.on_open, (query, view))
            if code and self.copy_cmd:
                n.add_action("copy", f"Copy {code}", self.on_copy, code)
                GLib.timeout_add_seconds(CODE_LIFETIME, self.expire, n)
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
    parser.add_argument("--copy", dest="copy_cmd", help="command a one-time code is piped to")
    parser.add_argument("--print", dest="print_only", action="store_true", help="print instead of notifying")
    parser.add_argument(
        "--detect",
        action="store_true",
        help="read batches (one JSON array per line) on stdin, print each message's one-time code",
    )
    args = parser.parse_args()

    if args.detect:
        for line in sys.stdin:
            for m in json.loads(line):
                code = one_time_code(m.get("subject"), visible_text(m.get("text"), m.get("html")))
                print(f"{code or '-'}\t{sender(m.get('from'))}\t{subject(m.get('subject'))}")
        return

    sock = listening_socket(args.socket)
    daemon = Daemon(args.icon, args.open_cmd, args.copy_cmd, args.print_only)
    if not args.print_only:
        Notify.init(APP)
    GLib.io_add_watch(sock.fileno(), GLib.IO_IN, lambda _fd, cond: daemon.on_connection(sock, cond))
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
