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

      # `mail-open [--view] <notmuch query>`: a new terminal window
      # (dotfiles.terminal, gui) with a fresh aerc of just the notmuch account
      # (`meta`, aerc.nix) on those messages, for clicked notifications;
      # --view also opens the (single) message.
      #
      # aerc runs one command per launch and takes more over IPC, whose socket
      # is $XDG_RUNTIME_DIR/aerc.sock: shared with any aerc already open (and
      # its active account tab). So this one gets a private runtime dir that
      # links everything in the real one (Wayland, D-Bus, gpg-agent sockets)
      # except aerc.sock; `:view` is sent there once the message list loads.
      mail-open = pkgs.writeShellApplication {
        name = "mail-open";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          aerc=${lib.getExe config.programs.aerc.package}
          view=0
          if [ "''${1:-}" = --view ]; then
            view=1
            shift
          fi
          query=$1

          rt=$(mktemp -d "$XDG_RUNTIME_DIR/mail-open.XXXXXX")
          for f in "$XDG_RUNTIME_DIR"/*; do
            case ''${f##*/} in
              aerc.sock | mail-open.*) ;;
              *) ln -s "$f" "$rt/" ;;
            esac
          done

          # shellcheck disable=SC2016 # the inner sh expands its own arguments
          ${lib.getExe config.dotfiles.terminal.package} -e \
            sh -c 'XDG_RUNTIME_DIR="$1" "$2" -a meta ":cf $3"; rm -rf "$1"' \
            mail-open "$rt" "$aerc" "$query" &

          [ "$view" = 1 ] || exit 0
          # Wait for this aerc's IPC socket, then for :view to succeed (it
          # fails until the query's message list has loaded); ~15s at most.
          # Only call aerc once the socket exists: without a server to talk to
          # it would start an instance of its own here.
          for _ in $(seq 75); do
            if [ -S "$rt/aerc.sock" ] &&
              [ -z "$(XDG_RUNTIME_DIR=$rt "$aerc" :view 2>&1)" ]; then
              exit 0
            fi
            sleep 0.2
          done
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
