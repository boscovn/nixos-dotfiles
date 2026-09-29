{
  pkgs,
  config,
  lib,
  host,
  ...
}:
let
  # Thunderbird is a GUI app; only useful alongside the desktop profile.
  desktop = builtins.elem "desktop" host.profiles;

  # Structural: by folder, always applied to all mail.
  folderRules = [
    "+sent -inbox -- folder:personal/Sent"
    "+draft -inbox -- folder:personal/Drafts"
    "+trash -inbox -- folder:personal/Trash"
    "+spam -inbox -- folder:personal/Junk"
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
in
{
  home.packages = with pkgs; [
    hydroxide
    maildir-rank-addr
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
        maildir-account-path = "personal";
        copy-to = "Sent";
        postpone = "Drafts";

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
      filters = {
        "text/plain" =
          "${pkgs.aerc}/libexec/aerc/filters/colorize | ${pkgs.aerc}/libexec/aerc/filters/wrap";
        "text/calendar" = "${pkgs.gawk}/bin/awk -f ${pkgs.aerc}/libexec/aerc/filters/calendar";
        "text/html" = "${pkgs.aerc}/libexec/aerc/filters/html | ${pkgs.aerc}/libexec/aerc/filters/colorize";
        "message/delivery-status" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        "message/rfc822" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        "application/x-sh" = "${pkgs.bat}/bin/bat -fP -l sh";
        "application/pdf" = "${pkgs.poppler-utils}/bin/pdftotext - -layout -nopgbrk -q -";
      };
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
      primary = true;
      realName = "Bosco Vallejo-Nágera";
      passwordCommand = "gopass show bosco@vallejonagera.xyz";
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
      passwordCommand = "gopass show mail/no8do.com";
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
    Sent	folder:personal/Sent
    Drafts	folder:personal/Drafts
    Trash	folder:personal/Trash
    Spam	tag:spam
    Finance	tag:finance
    Shopping	tag:shopping
    Jobs	tag:jobs
    Social	tag:social
    Newsletters	tag:newsletter
    Travel	tag:travel
    iCloud	folder:personal/icloud
    UTAD	tag:utad
    All	not tag:trash and not tag:spam
  '';

  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "mbsync --all";
      postNew = "notmuch tag --batch --input=${newMailBatch}";
    };
  };
}
