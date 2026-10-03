# Desktop notifications for new mail (homeManager.email, gui hosts only: they
# need a notification daemon, and clicks a terminal). notmuch's post-new hook
# (notmuch.nix) sends the new messages as JSON to a socket-activated daemon
# (notmuch-notify.py) that shows them, opens clicked ones in aerc and offers
# to copy one-time codes.
{
  homeManager.email =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      socket = "%t/notmuch-notify.sock";

      # The daemon: libnotify through PyGObject, which needs the Notify
      # typelib and the GLib and GdkPixbuf ones it depends on. `exec` keeps
      # the PID systemd's LISTEN_PID names.
      notmuch-notify = pkgs.writeShellApplication {
        name = "notmuch-notify";
        runtimeEnv.GI_TYPELIB_PATH = lib.makeSearchPath "lib/girepository-1.0" [
          pkgs.libnotify
          pkgs.glib.out
          pkgs.gdk-pixbuf
        ];
        text = ''
          exec ${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 ${./notmuch-notify.py} "$@"
        '';
      };

      # A message per entry, with its body text for the daemon's one-time
      # code detection: the first text/plain part, else the first text/html
      # one (flagged, the daemon strips its tags), truncated. Attachments
      # aren't in notmuch's JSON.
      batchFilter = pkgs.writeText "notmuch-notify.jq" ''
        def parts: .body[]? | .. | objects
          | select(has("content-type") and (.content | type) == "string");
        [.. | objects | select(has("id") and has("headers"))
          | ([parts | select(."content-type" | ascii_downcase == "text/plain") | .content] | first) as $plain
          | ([parts | select(."content-type" | ascii_downcase == "text/html") | .content] | first) as $html
          | {id, date: .timestamp, from: .headers.From, subject: .headers.Subject,
             text: (if $plain then $plain[:8000] else ($html // "")[:65536] end),
             html: ($plain == null and $html != null)}]
      '';

      # `notmuch-notify-send [query]`, run by the post-new hook before `new`
      # is cleared: the new, unread messages (not spam/trash, tagged by then)
      # as one JSON batch to the daemon's socket. Nothing is sent without new
      # mail; with systemd holding the socket, the daemon needn't be running.
      notmuch-notify-send = pkgs.writeShellApplication {
        name = "notmuch-notify-send";
        runtimeInputs = [
          pkgs.notmuch
          pkgs.jq
          pkgs.socat
        ];
        text = ''
          query=''${1:-tag:new and tag:unread and not tag:spam and not tag:trash}
          batch=$(notmuch show --format=json --entire-thread=false --include-html "$query" |
            jq -c -f ${batchFilter})
          [ "$batch" != "[]" ] || exit 0
          printf '%s\n' "$batch" |
            socat -u - "UNIX-CONNECT:''${NOTMUCH_NOTIFY_SOCKET:-$XDG_RUNTIME_DIR/notmuch-notify.sock}"
        '';
      };

      # A notification's "Copy <code>" button: the code on stdin, marked
      # sensitive so clipboard managers/histories skip it.
      copy-code = pkgs.writeShellScript "notmuch-notify-copy" ''
        exec ${pkgs.wl-clipboard}/bin/wl-copy --sensitive
      '';

      # `mail-open [--view] <notmuch query>`, for clicked notifications: show
      # those messages in the running aerc, over its IPC socket, starting one
      # in a new terminal window (dotfiles.terminal, gui) if none runs.
      # Switches to the notmuch account's tab (`meta`, aerc.nix) and opens the
      # query; --view also opens the (single) message.
      mail-open = pkgs.writeShellApplication {
        name = "mail-open";
        # Everything it runs: it inherits imapnotify's minimal PATH.
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.procps
        ];
        text = ''
          aerc=${lib.getExe config.programs.aerc.package}
          view=0
          if [ "''${1:-}" = --view ]; then
            view=1
            shift
          fi
          query=$1

          # A live aerc owns the socket. Never call `aerc :cmd` without one:
          # it would start an aerc of its own here, with no terminal.
          running() {
            [ -S "$XDG_RUNTIME_DIR/aerc.sock" ] && pgrep -u "$(id -u)" -x .aerc-wrapped >/dev/null
          }
          # Run a command in it. The client always exits 0 and prints its
          # debug log, so a failure is its "response: <error>" line.
          ipc() { ! "$aerc" "$1" 2>&1 | grep -q '^response:'; }
          # ~15s at most per wait.
          retry() {
            for _ in $(seq 75); do
              "$@" && return 0
              sleep 0.2
            done
            return 1
          }

          if ! running; then
            ${lib.getExe config.dotfiles.terminal.package} -e "$aerc" &
            retry running || exit 1
          fi
          # The account tab can lag behind the socket while aerc starts.
          retry ipc ":change-tab meta" || exit 1
          ipc ":cf $query"
          [ "$view" = 1 ] || exit 0
          # :view returns success but does nothing while the query's message
          # list is still empty (loading). Once a viewer has the focus, :view
          # is an unknown command there: that's the sign it opened. Spaced
          # out so a viewer still opening isn't opened twice.
          for _ in $(seq 20); do
            "$aerc" ":view" 2>&1 | grep -q '^response: Unknown command view' && exit 0
            sleep 0.7
          done
          exit 1
        '';
      };

    in
    lib.mkIf config.dotfiles.gui {
      # Held by systemd from login; the first batch starts the service.
      systemd.user.sockets.notmuch-notify = {
        Unit.Description = "Socket for new-mail notifications";
        Socket = {
          ListenStream = socket;
          SocketMode = "0600";
        };
        Install.WantedBy = [ "sockets.target" ];
      };
      # Lives for the graphical session (it needs the notification server);
      # the socket stays, so the next session starts it again on demand.
      systemd.user.services.notmuch-notify = {
        Unit = {
          Description = "New-mail notifications";
          Requires = [ "notmuch-notify.socket" ];
          After = [
            "notmuch-notify.socket"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          # Clicking a notification opens its message(s) in aerc (mail-open);
          # one with a one-time code also has a button copying it.
          ExecStart = lib.escapeShellArgs [
            "${notmuch-notify}/bin/notmuch-notify"
            "--icon"
            "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/internet-mail.svg"
            "--open"
            "${mail-open}/bin/mail-open"
            "--copy"
            "${copy-code}"
          ];
          Restart = "on-failure";
        };
      };

      # Between notmuch.nix's tag rules and its clearing of `new`. A failed
      # notification must not stop the hook.
      programs.notmuch.hooks.postNew = "${notmuch-notify-send}/bin/notmuch-notify-send || true";
    };
}
