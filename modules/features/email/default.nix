# Terminal mail stack (aerc, mbsync, msmtp, notmuch, hydroxide), plus
# Thunderbird when the gui bundle is also imported. Opt-in: needs the gopass
# setup and a ~/Maildir.
{
  homeManager.email =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      # Thunderbird is a GUI app; only with the gui bundle.
      desktop = config.dotfiles.gui;

      # Folder names come from the account (accounts.email.accounts.personal
      # .folders below); home-manager has no option for the junk folder.
      personal = config.accounts.email.accounts.personal;
      junkFolder = "Junk";
      # A notmuch query for one of the personal account's maildir folders.
      folder = name: "folder:${personal.maildir.path}/${name}";

      # Structural: by folder, always applied to all mail.
      folderRules = [
        "+sent -inbox -- ${folder personal.folders.sent}"
        "+draft -inbox -- ${folder personal.folders.drafts}"
        "+trash -inbox -- ${folder personal.folders.trash}"
        "+spam -inbox -- ${folder junkFolder}"
      ];

      # Category tags. Applied to new mail by the post-new hook, and to all mail
      # by `notmuch-retag`, so both always use the same rules.
      categoryRules = {
        finance = "to:fin.outlying285@simplelogin.com or from:revolut or from:paypal or from:coinbase or from:stripe or from:bbva or from:n26";
        shopping = "to:vinted.bust057@simplelogin.com or from:silbon or from:aliexpress or from:amazon or from:boots or from:uber";
        social = "to:socbos+twitter@simplelogin.com or from:instagram or from:twitter or from:facebookmail";
        jobs = "from:pagepersonnel or from:infojobs or from:relocate or from:appfigures";
        travel = "from:iberia or from:balearia or from:booking or from:airbnb or from:renfe or from:parador";
        newsletter = "to:simplelogin-newsletter.makeover699@simplelogin.com or from:voxespana or from:elespanol or from:myglo or from:lateral or from:riela or from:steam";
        # U-tad (Office 365) mail: the tenant blocks third-party IMAP/SMTP
        # clients, so it is forwarded from Outlook to a SimpleLogin alias.
        utad = "to:juan.vallejo@live.u-tad.com or to:utadfwd.culminate455@aleeas.com";
      };

      # A `notmuch tag --batch` file (see notmuch-tag(1), TAG FILE FORMAT).
      # `scope` is prepended to every category query.
      mkTagBatch =
        name: scope: extra:
        pkgs.writeText "notmuch-${name}.batch" (
          lib.concatLines (
            folderRules
            ++ lib.mapAttrsToList (tag: query: "+${tag} -- ${scope}(${query})") categoryRules
            ++ extra
          )
        );

      newMailBatch = mkTagBatch "new" "tag:new and " [ "-new -- tag:new" ];
      allMailBatch = mkTagBatch "all" "" [ ];

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

      # IMAP IDLE on the inbox; on new mail, sync this account's mbsync
      # channel (named after the account) and index it.
      imapnotifyFor = channel: {
        enable = true;
        boxes = [ "INBOX" ];
        onNotify = "${mail-sync}/bin/mail-sync ${channel}";
      };

      aercFilters = "${config.programs.aerc.package}/libexec/aerc/filters";

      # aerc filter for any application/* part: senders often label PDFs,
      # spreadsheets or archives application/octet-stream (or bogus types like
      # application/base64), so the real type comes from the attachment's
      # extension or, failing that, its content (libmagic).
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
        text = ''
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          name=''${AERC_FILENAME:-attachment}
          f="$tmp/''${name//\//_}"
          cat >"$f"

          ext=""
          [[ $name == *.* ]] && ext=''${name##*.}
          ext=''${ext,,}
          mime=$(file --brief --mime-type "$f")

          doc() { pandoc --from "$1" --to plain --columns=100 "$f"; }
          # Blank or separator-only rows (common in spreadsheets) would make
          # pandoc read an empty header row and reject the rest.
          table() { sed '/^[,[:space:]]*$/d' "$2" | pandoc --from "$1" --to plain --columns=160; }

          case "$ext:$mime" in
            pdf:* | *:application/pdf)
              # -layout keeps columns (receipts, tables); trim its padding and collapse
              # blank runs. No fmt: it splits deeply indented layout lines word by word.
              pdftotext -layout -nopgbrk -q "$f" - | sed 's/[[:space:]]*$//' | cat -s ;;
            docx:* | *:application/vnd.openxmlformats-officedocument.wordprocessingml.document)
              doc docx ;;
            odt:* | *:application/vnd.oasis.opendocument.text)
              doc odt ;;
            epub:* | *:application/epub+zip)
              doc epub ;;
            rtf:* | *:text/rtf | *:application/rtf)
              doc rtf ;;
            ipynb:*)
              doc ipynb ;;
            xlsx:* | *:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
              xlsx2csv --all "$f" "$tmp/sheets" >/dev/null
              for sheet in "$tmp"/sheets/*.csv; do
                printf '== %s ==\n\n' "$(basename "$sheet" .csv)"
                table csv "$sheet"
                echo
              done ;;
            csv:* | *:text/csv)
              table csv "$f" ;;
            tsv:* | *:text/tab-separated-values)
              table tsv "$f" ;;
            zip:* | 7z:* | rar:* | tar:* | tgz:* | gz:* | xz:* | zst:* \
              | *:application/zip | *:application/x-7z-compressed | *:application/x-rar \
              | *:application/x-tar | *:application/gzip | *:application/x-xz | *:application/zstd)
              bsdtar -tvf "$f" ;;
            ics:* | *:text/calendar)
              ${aercFilters}/calendar <"$f" ;;
            p7s:* | p7m:* | *:application/pkcs7-signature)
              openssl pkcs7 -inform DER -in "$f" -print_certs -noout ;;
            json:* | *:application/json)
              jq --color-output . "$f" ;;
            *:image/*)
              chafa --format symbols --size 100x40 "$f" ;;
            *:text/*)
              bat --color=always --paging=never --style=plain --file-name="$name" "$f" ;;
            *)
              printf '%s\n\n%s\n' "$(file --brief "$f")" "No viewer for this type: :open or :save it." ;;
          esac
        '';
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
      home.packages = with pkgs; [
        hydroxide
        maildir-rank-addr
        mail-sync
        # Re-apply every tag rule to all mail, e.g. after adding or changing one.
        # Only adds tags; it never removes a tag a changed rule no longer matches.
        (writeShellScriptBin "notmuch-retag" ''
          exec ${notmuch}/bin/notmuch tag --batch --input=${allMailBatch}
        '')
      ];
      programs.mbsync.enable = true;
      programs.msmtp.enable = true;
      programs.thunderbird.enable = desktop;
      programs.aerc = {
        enable = true;
        extraAccounts = {
          meta = {
            source = "notmuch://";
            exclude-tags = "archive,spam";
            # maildir-store = "${config.home.homeDirectory}/Maildir";
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
            address-book-cmd = "${pkgs.ripgrep}/bin/rg --color=never -m 100 %s ${config.home.homeDirectory}/.cache/maildir-rank-addr/addressbook.tsv";
            # address-book-cmd = "${pkgs.notmuch}/bin/notmuch address %s";
          };
          # Bundled filters (wrap, colorize, html, calendar) are on aerc's
          # filter PATH, so they're referenced by name.
          filters = lib.concatMapStrings (f: "${builtins.elemAt f 0} = ${builtins.elemAt f 1}\n") filters;
        };
      };

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
          # (programs.aerc.extraAccounts below) and its query-map; this account's
          # own aerc stanza was only ever a redundant, unused tab, and
          # home-manager's aerc module still emits the pre-0.22 maildir-store /
          # embedded-path notmuch:// source that aerc now warns as deprecated on
          # every startup.
          aerc.enable = false;
          # The maildir's folder names (as mbsync creates them from the IMAP
          # server); the notmuch rules and aerc settings above use these.
          folders = {
            inbox = "Inbox";
            sent = "Sent";
            drafts = "Drafts";
            trash = "Trash";
          };
          imapnotify = imapnotifyFor "personal";
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
          folders = {
            inbox = "Inbox";
            sent = "Sent";
            drafts = "Drafts";
            trash = "Trash";
          };
          imapnotify = imapnotifyFor "old";
          passwordCommand = "gopass show -o mail/no8do.com";
        };
      };
      home.file.".config/maildir-rank-addr/config".text = /* toml */ ''
        maildir = "~/Maildir/"
        addresses = [
          "bosco@vallejonagera.xyz",
          "bosco@no8do.com"
        ]
        template = "{{.Address}}\t{{.Name}}"
      '';

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

      programs.notmuch = {
        enable = true;
        # `new` marks mail for the new-mail tag rules (newMailBatch), which
        # remove it once applied. Without it those rules matched nothing.
        new.tags = [
          "new"
          "unread"
          "inbox"
        ];
        hooks = {
          # No pre-new sync: mail-sync (run by imapnotify) syncs one account,
          # then runs `notmuch new`.
          postNew = "notmuch tag --batch --input=${newMailBatch}";
        };
      };

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
      # home-manager starts them at boot (default.target), before the Wayland
      # session: gopass then needs the GPG passphrase, pinentry has no screen to
      # prompt on, and they fail until a retry lands after login. Tied to the
      # graphical session, the first one prompts once and the other uses
      # gpg-agent's cache.
      systemd.user.services =
        lib.genAttrs
          (map (account: "imapnotify-${account}") [
            "personal"
            "old"
          ])
          (_: {
            Unit = {
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
          });
    };
}
