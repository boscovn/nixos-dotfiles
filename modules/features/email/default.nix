# Terminal mail stack (aerc, mbsync, msmtp, notmuch, hydroxide), plus
# Thunderbird when the gui bundle is also imported. Opt-in: needs the gopass
# setup and a ~/Maildir.
#
# All of this directory's modules add to homeManager.email:
# - default.nix: the accounts, mbsync/msmtp/Thunderbird, address book
# - notmuch.nix: tag rules, notmuch-retag, notmuch config and post-new hook
# - sync.nix: mail-sync and the imapnotify (IMAP IDLE) services
# - notify.nix (+ notmuch-notify.py): new-mail notification daemon, mail-open
# - aerc.nix: aerc settings, query map, viewer filters
{
  homeManager.email =
    { config, pkgs, ... }:
    let
      # Thunderbird is a GUI app; only with the gui bundle.
      desktop = config.dotfiles.gui;

      # The maildir's folder names (as mbsync creates them from the IMAP
      # server); the notmuch rules and aerc settings use these.
      folders = {
        inbox = "Inbox";
        sent = "Sent";
        drafts = "Drafts";
        trash = "Trash";
      };
    in
    {
      home.packages = with pkgs; [
        hydroxide
        maildir-rank-addr
      ];
      programs.mbsync.enable = true;
      programs.msmtp.enable = true;
      programs.thunderbird.enable = desktop;

      accounts.email = {
        accounts.personal = {
          address = "bosco@vallejonagera.xyz";
          imap.host = "imap.hostinger.com";
          mbsync = {
            enable = true;
            create = "maildir";
          };
          msmtp.enable = true;
          thunderbird.enable = desktop;
          notmuch.enable = true;
          # aerc is driven entirely through the notmuch-backed [meta] account
          # (aerc.nix) and its query-map; this account's own aerc stanza was
          # only ever a redundant, unused tab, and home-manager's aerc module
          # still emits the pre-0.22 maildir-store / embedded-path notmuch://
          # source that aerc now warns as deprecated on every startup.
          aerc.enable = false;
          inherit folders;
          primary = true;
          realName = "Bosco Vallejo-Nágera";
          passwordCommand = "gopass show -o bosco@vallejonagera.xyz";
          smtp = {
            host = "smtp.hostinger.com";
          };
          userName = "bosco@vallejonagera.xyz";
        };
        accounts.old = {
          address = "bosco@no8do.com";
          userName = "bosco@no8do.com";
          realName = "Bosco Vallejo-Nágera";
          imap.host = "no8do-com.correoseguro.dinaserver.com";
          smtp.host = "no8do-com.correoseguro.dinaserver.com";
          mbsync = {
            enable = true;
            create = "maildir";
          };
          msmtp.enable = true;
          aerc.enable = true;
          inherit folders;
          passwordCommand = "gopass show -o mail/no8do.com";
        };
      };

      # Address book for aerc's address-book-cmd (aerc.nix).
      home.file.".config/maildir-rank-addr/config".text = /* toml */ ''
        maildir = "~/Maildir/"
        addresses = [
          "bosco@vallejonagera.xyz",
          "bosco@no8do.com"
        ]
        template = "{{.Address}}\t{{.Name}}"
      '';
    };
}
