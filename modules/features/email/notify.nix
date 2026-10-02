# Desktop notifications for new mail (homeManager.email, gui hosts only: they
# need a notification daemon, and clicks a terminal). notify-new-mail.py runs
# in notmuch's post-new hook (notmuch.nix); clicking one opens it in aerc.
{
  homeManager.email =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # notify-new-mail.py: notmuch2 bindings for the query, libnotify (through
      # PyGObject, which needs the Notify typelib and the GLib and GdkPixbuf
      # ones it depends on) for notifications.
      notify-new-mail = pkgs.writeShellApplication {
        name = "notify-new-mail";
        runtimeEnv.GI_TYPELIB_PATH = lib.makeSearchPath "lib/girepository-1.0" [
          pkgs.libnotify
          pkgs.glib.out
          pkgs.gdk-pixbuf
        ];
        text = ''
          exec ${
            pkgs.python3.withPackages (ps: [
              ps.notmuch2
              ps.pygobject3
            ])
          }/bin/python3 ${./notify-new-mail.py} "$@"
        '';
      };

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

      # Clicking a notification opens its message(s) in aerc (mail-open).
      notifyCommand = lib.escapeShellArgs [
        "${notify-new-mail}/bin/notify-new-mail"
        "--icon"
        "${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/internet-mail.svg"
        "--open"
        "${mail-open}/bin/mail-open"
      ];
    in
    lib.mkIf config.dotfiles.gui {
      # Between notmuch.nix's tag rules and its clearing of `new`. A failed
      # notification must not stop the hook.
      programs.notmuch.hooks.postNew = "${notifyCommand} || true";
    };
}
