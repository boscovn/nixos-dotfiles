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

      bin = pkg: name: "${pkg}/bin/${name}";
      pandoc = from: "${bin pkgs.pandoc "pandoc"} --from ${from} --to plain --columns=100";
      # Blank or separator-only rows (common in spreadsheets) would make pandoc
      # read an empty header row and reject the rest.
      table =
        from:
        "sed '/^[,[:space:]]*$/d' | ${bin pkgs.pandoc "pandoc"} --from ${from} --to plain --columns=160";

      # The one multi-step viewer: xlsx2csv needs a file to write one CSV per
      # sheet (reading stdin it merges them), each shown as its own table.
      xlsx-view = pkgs.writeShellApplication {
        name = "xlsx-view";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.xlsx2csv
        ];
        text = ''
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          cat >"$tmp/book.xlsx"
          xlsx2csv --all "$tmp/book.xlsx" "$tmp/sheets" >/dev/null
          for sheet in "$tmp"/sheets/*.csv; do
            printf '== %s ==\n\n' "$(basename "$sheet" .csv)"
            { ${table "csv"}; } <"$sheet"
            echo
          done
        '';
      };

      # Attachment viewers: matched by file name first, as senders often label
      # PDFs, documents or archives application/octet-stream,
      # x-file-download or even application/base64; then by MIME type.
      # Anything else (including mislabeled images) gets no filter, so aerc
      # shows its open/save menu.
      viewers = [
        {
          exts = [ "pdf" ];
          types = [ "application/pdf" ];
          # -layout keeps columns (receipts, tables); trim its padding and
          # collapse blank runs.
          cmd = "${bin pkgs.poppler-utils "pdftotext"} -layout -nopgbrk -q - - | sed 's/[[:space:]]*$//' | cat -s";
        }
        {
          exts = [ "docx" ];
          types = [ "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ];
          cmd = pandoc "docx";
        }
        {
          exts = [ "odt" ];
          types = [ "application/vnd.oasis.opendocument.text" ];
          cmd = pandoc "odt";
        }
        {
          exts = [ "epub" ];
          types = [ "application/epub+zip" ];
          cmd = pandoc "epub";
        }
        {
          exts = [ "rtf" ];
          types = [
            "application/rtf"
            "text/rtf"
          ];
          cmd = pandoc "rtf";
        }
        {
          exts = [ "ipynb" ];
          types = [ ];
          cmd = pandoc "ipynb";
        }
        {
          exts = [ "xlsx" ];
          types = [ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ];
          cmd = "${xlsx-view}/bin/xlsx-view";
        }
        {
          exts = [ "csv" ];
          types = [ "text/csv" ];
          cmd = table "csv";
        }
        {
          exts = [ "tsv" ];
          types = [ "text/tab-separated-values" ];
          cmd = table "tsv";
        }
        {
          exts = [
            "zip"
            "7z"
            "rar"
            "tar"
            "tgz"
            "gz"
            "xz"
            "zst"
          ];
          types = [
            "application/zip"
            "application/x-zip-compressed"
            "application/x-7z-compressed"
            "application/x-rar"
            "application/x-tar"
            "application/gzip"
            "application/x-xz"
            "application/zstd"
          ];
          cmd = "${bin pkgs.libarchive "bsdtar"} -tvf -";
        }
        {
          exts = [ "ics" ];
          types = [
            "text/calendar"
            "application/ics"
          ];
          cmd = "calendar";
        }
        {
          # S/MIME signatures: the signer's certificate chain.
          exts = [
            "p7s"
            "p7m"
          ];
          types = [ "application/pkcs7-signature" ];
          cmd = "${bin pkgs.openssl "openssl"} pkcs7 -inform DER -print_certs -noout";
        }
        {
          exts = [ "json" ];
          types = [ "application/json" ];
          cmd = "${bin pkgs.jq "jq"} --color-output .";
        }
      ];

      # aerc uses the first filter that matches, so this is an ordered list:
      # file names (mislabeled attachments) first, then mail bodies and MIME
      # types, wildcards last. image/* has no filter on purpose: aerc then
      # draws images itself with the terminal's graphics protocol.
      filters =
        map (v: [
          ".filename,~(?i)\\.(${lib.concatStringsSep "|" v.exts})$"
          v.cmd
        ]) viewers
        ++ [
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
            "text/markdown"
            "${pandoc "gfm"} | colorize"
          ]
        ]
        ++ lib.concatMap (
          v:
          map (type: [
            type
            v.cmd
          ]) v.types
        ) viewers
        ++ [
          [
            "text/*"
            ''${bin pkgs.bat "bat"} --color=always --paging=never --style=plain --file-name="$AERC_FILENAME"''
          ]
          [
            "message/delivery-status"
            "colorize"
          ]
          [
            "message/rfc822"
            "${bin pkgs.caeml "caeml"} | colorize"
          ]
          [
            "application/pgp-signature"
            "cat"
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
            # -c: paint each screen from the top line down, so a message starts
            # at the top instead of scrolling in from the bottom.
            pager = "${pkgs.less}/bin/less -Rc";
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
