# aerc (homeManager.email): one notmuch-backed account (`meta`, also used by
# notify.nix's mail-open) whose folders are the query map, plus viewer filters.
{
  homeManager.email =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      personal = config.accounts.email.accounts.personal;
      # A notmuch query for one of the personal account's maildir folders.
      folder = name: "folder:${personal.maildir.path}/${name}";

      aercFilters = "${config.programs.aerc.package}/libexec/aerc/filters";

      # Viewer for any application/* part; see aerc-attachment.sh.
      aerc-attachment = pkgs.writeShellApplication {
        name = "aerc-attachment";
        runtimeInputs = with pkgs; [
          bat
          chafa
          coreutils
          file
          jq
          libarchive
          openssl
          pandoc
          poppler-utils
          xlsx2csv
        ];
        text = lib.replaceStrings [ "@calendar@" ] [ "${aercFilters}/calendar" ] (
          builtins.readFile ./aerc-attachment.sh
        );
      };

      # aerc uses the first filter whose type matches, so this is a list
      # (specific types first, wildcards last), written out in this order.
      # image/* has no filter on purpose: aerc then draws images itself with
      # the best protocol the terminal supports (kitty graphics in ghostty).
      filters = [
        [
          "text/plain"
          "wrap -w 100 | colorize"
        ]
        [
          "text/html"
          "html | colorize"
        ]
        [
          "text/x-amp-html"
          "html | colorize"
        ]
        [
          "text/calendar"
          "calendar"
        ]
        [
          "text/markdown"
          "${pkgs.pandoc}/bin/pandoc --from gfm --to plain --columns=100 | colorize"
        ]
        [
          "text/*"
          ''${pkgs.bat}/bin/bat --color=always --paging=never --style=plain --file-name="$AERC_FILENAME"''
        ]
        [
          "message/delivery-status"
          "colorize"
        ]
        [
          "message/rfc822"
          "${pkgs.caeml}/bin/caeml | colorize"
        ]
        [
          "application/ics"
          "calendar"
        ]
        [
          "application/pgp-signature"
          "cat"
        ]
        [
          "application/*"
          "${aerc-attachment}/bin/aerc-attachment"
        ]
      ];
    in
    {
      programs.aerc = {
        enable = true;
        extraAccounts = {
          meta = {
            source = "notmuch://";
            exclude-tags = "archive,spam";
            from = "Bosco Vallejo-Nágera <bosco@vallejonagera.xyz>";
            outgoing = "msmtp --read-envelope-from --read-recipients";
            multi-file-strategy = "act-all";
            # Resolves folder names below against ~/Maildir/personal, which is
            # where mbsync puts the account (see accounts.email.accounts.personal).
            maildir-account-path = personal.maildir.path;
            copy-to = personal.folders.sent;
            postpone = personal.folders.drafts;

            query-map = "${config.home.homeDirectory}/.config/aerc/query-map";
          };
        };
        extraConfig = {
          general.unsafe-accounts-conf = true;
          viewer = {
            pager = "${pkgs.less}/bin/less -R";
          };
          compose = {
            file-picker-cmd = "${pkgs.yazi}/bin/yazi --chooser-file %f";
            # Built from ~/Maildir by maildir-rank-addr (default.nix).
            address-book-cmd = "${pkgs.ripgrep}/bin/rg --color=never -m 100 %s ${config.home.homeDirectory}/.cache/maildir-rank-addr/addressbook.tsv";
          };
          # Bundled filters (wrap, colorize, html, calendar) are on aerc's
          # filter PATH, so they're referenced by name.
          filters = lib.concatMapStrings (f: "${builtins.elemAt f 0} = ${builtins.elemAt f 1}\n") filters;
        };
      };

      home.file.".config/aerc/query-map".text = ''
        Inbox	tag:inbox and not tag:sent and not tag:trash and not tag:spam
        Unread	tag:unread and not tag:spam and not tag:trash
        Sent	${folder personal.folders.sent}
        Drafts	${folder personal.folders.drafts}
        Trash	${folder personal.folders.trash}
        Spam	tag:spam
        Finance	tag:finance
        Shopping	tag:shopping
        Jobs	tag:jobs
        Social	tag:social
        Newsletters	tag:newsletter
        Travel	tag:travel
        iCloud	${folder "icloud"}
        UTAD	tag:utad
        All	not tag:trash and not tag:spam
      '';
    };
}
