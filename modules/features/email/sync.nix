# Fetching mail (homeManager.email): `mail-sync <account>`, run by an
# imapnotify service per account on new mail (IMAP IDLE).
{
  homeManager.email =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # mbsync channels are named after the accounts (default.nix).
      accounts = [
        "personal"
        "old"
      ];

      # `mail-sync <account>`: sync that account's mbsync channel, then index
      # with `notmuch new`, whose post-new hook tags the new mail. What
      # imapnotify runs on new mail; there is no sync-everything mode. The lock
      # keeps runs (and their notmuch writes) from overlapping when both
      # accounts get mail at once.
      mail-sync = pkgs.writeShellApplication {
        name = "mail-sync";
        runtimeInputs = [
          config.programs.mbsync.package
          pkgs.notmuch
          pkgs.util-linux
          # mbsync's PassCmd (gopass show ...)
          pkgs.gopass
          pkgs.gnupg
        ];
        text = ''
          if [ $# -ne 1 ]; then
            echo "usage: mail-sync <account>   (an mbsync channel: personal, old)" >&2
            exit 2
          fi
          exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/mail-sync.lock"
          flock 9
          mbsync "$1"
          notmuch new
        '';
      };
    in
    {
      home.packages = [ mail-sync ];

      # New mail over IMAP IDLE (both servers support it): sync and index that
      # account right away instead of waiting for a manual `notmuch new`.
      services.imapnotify = {
        enable = true;
        # The service's whole PATH. goimapnotify runs its commands with a bare
        # `sh -c`, so it needs a shell; gopass/gnupg for the accounts'
        # passwordCommand (gopass show -o ...).
        path = [
          pkgs.bash
          pkgs.coreutils
          pkgs.gopass
          pkgs.gnupg
        ];
      };

      # IMAP IDLE on each inbox; on new mail, sync that account's channel.
      accounts.email.accounts = lib.genAttrs accounts (account: {
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "${mail-sync}/bin/mail-sync ${account}";
        };
      });

      # home-manager starts them at boot (default.target), before the Wayland
      # session: gopass then needs the GPG passphrase, pinentry has no screen to
      # prompt on, and they fail until a retry lands after login. Tied to the
      # graphical session, the first one prompts once and the other uses
      # gpg-agent's cache.
      systemd.user.services = lib.genAttrs (map (account: "imapnotify-${account}") accounts) (_: {
        Unit = {
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
      });
    };
}
