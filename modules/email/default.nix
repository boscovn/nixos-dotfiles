{
  pkgs,
  lib,
  config,
  ...
}:
{

  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.aerc = {
    enable = true;
    extraAccounts = {
      meta = {
        source = "notmuch://${config.home.homeDirectory}/Maildir";
        from = "Bosco Vallejo-Nágera <bosco@vallejonagera.xyz>";
        outgoing = "msmtp --read-envelope-from --read-recipients";
        # query-map = "${config.home.file.".config/aerc/query-map"}";
      };
    };
    extraConfig = {
      general.unsafe-accounts-conf = true;
      viewer = {
        pager = "${pkgs.less}/bin/less -R";
      };
      compose = {
        file-picker-cmd = "${pkgs.yazi}/bin/yazi --chooser-file %f";
      };
      filters = {
        "text/plain" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        "text/calendar" = "${pkgs.gawk}/bin/awk -f ${pkgs.aerc}/libexec/aerc/filters/calendar";
        "text/html" =
          "${pkgs.aerc}/libexec/aerc/filters/html | ${pkgs.aerc}/libexec/aerc/filters/colorize"; # Requires w3m, dante
        # "text/*" =
        #   ''${pkgs.bat}/bin/bat -fP --file-name="$AERC_FILENAME "'';
        "message/delivery-status" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        "message/rfc822" = "${pkgs.aerc}/libexec/aerc/filters/colorize";
        "application/x-sh" = "${pkgs.bat}/bin/bat -fP -l sh";
        "application/pdf" = "${pkgs.poppler_utils}/bin/pdftotext - -layout -nopgbrk -q -";
        # "audio/*" = "${pkgs.mpv}/bin/mpv -";
        # "image/*" = "${pkgs.feh}/bin/feh -";
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
  programs.notmuch = {
    enable = true;
    hooks = {
      preNew = "mbsync --all";
    };
  };
}
