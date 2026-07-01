{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [ hydroxide ];
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.aerc = {
    enable = true;
    extraAccounts = {
      meta = {
        source = "notmuch://${config.home.homeDirectory}/Maildir";
        maildir-store = "${config.home.homeDirectory}/Maildir";
        from = "Bosco Vallejo-Nágera <bosco@vallejonagera.xyz>";
        outgoing = "msmtp --read-envelope-from --read-recipients";
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
        address-book-cmd = "${pkgs.notmuch}/bin/notmuch address %s";
      };
      filters = {
        "text/plain" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
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
      notmuch.enable = true;
      aerc.enable = true;
      primary = true;
      realName = "Bosco Vallejo-Nágera";
      passwordCommand = "gopass show bosco@vallejonagera.xyz";
      smtp = {
        host = "smtp.hostinger.com";
      };
      userName = "bosco@vallejonagera.xyz";
    };
  };

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
    All	not tag:trash and not tag:spam
  '';

  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "mbsync --all";
      postNew = ''
        # structural: apply to all mail in these folders, not just new
        notmuch tag +sent -inbox -- folder:personal/Sent
        notmuch tag +draft -inbox -- folder:personal/Drafts
        notmuch tag +trash -inbox -- folder:personal/Trash
        notmuch tag +spam -inbox -- folder:personal/Junk

        # category tags: only on new incoming mail
        notmuch tag +finance -- 'tag:new and (to:fin.outlying285@simplelogin.com or from:revolut or from:paypal or from:coinbase or from:stripe or from:bbva or from:n26)'
        notmuch tag +shopping -- 'tag:new and (to:vinted.bust057@simplelogin.com or from:silbon or from:aliexpress or from:amazon or from:boots or from:uber)'
        notmuch tag +social -- 'tag:new and (to:socbos+twitter@simplelogin.com or from:linkedin or from:instagram or from:twitter or from:facebookmail)'
        notmuch tag +jobs -- 'tag:new and (from:pagepersonnel or from:infojobs or from:relocate or from:appfigures)'
        notmuch tag +travel -- 'tag:new and (from:iberia or from:balearia or from:booking or from:airbnb or from:renfe or from:parador)'
        notmuch tag +newsletter -- 'tag:new and (to:simplelogin-newsletter.makeover699@simplelogin.com or from:voxespana or from:elespanol or from:myglo or from:lateral or from:riela or from:steam)'

        notmuch tag -new -- tag:new
      '';
    };
  };
}
