# Linux desktop session: Hyprland and friends, browsers, media, GUI apps, and
# the plumbing they need. Omit on WSL/darwin/servers.
{ pkgs, ... }:
let
  # Native messaging host for the Gopass Bridge extension: browsers invoke
  # this with the extension origin as argv[1], which gopass-jsonapi's own
  # "listen" subcommand ignores, so a thin wrapper is enough.
  gopassJsonapiWrapper = pkgs.writeShellScript "gopass-jsonapi-wrapper" ''
    exec ${pkgs.gopass-jsonapi}/bin/gopass-jsonapi listen
  '';
in
{
  imports = [
    ../wayland
    ../media.nix
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  home.packages = with pkgs; [
    android-tools
    corefonts
    firefox
    gopass-jsonapi
    kdePackages.dolphin
    liberation_ttf
    libva-utils
    onlyoffice-desktopeditors
    pavucontrol
    telegram-desktop
    usbutils
    v4l-utils
    vista-fonts
  ];

  fonts.fontconfig.enable = true;
  programs.foot.enable = true;
  programs.obsidian.enable = true;
  programs.zathura.enable = true;
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
    config = {
      save-position-on-quit = true;
    };
  };
  programs.imv.enable = true;
  programs.brave = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      { id = "kkhfnlkhiapbiehimabddjbimfaijdhk"; } # Gopass Bridge
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # vimium
    ];
  };
  xdg.configFile."BraveSoftware/Brave-Browser/NativeMessagingHosts/com.justwatch.gopass.json".text =
    builtins.toJSON
      {
        name = "com.justwatch.gopass";
        description = "Gopass wrapper to search and return passwords";
        path = "${gopassJsonapiWrapper}";
        type = "stdio";
        allowed_origins = [ "chrome-extension://kkhfnlkhiapbiehimabddjbimfaijdhk/" ];
      };

  # GNOME Keyring control socket path is always /run/user/$UID/keyring but
  # UWSM doesn't import GNOME_KEYRING_CONTROL from the PAM environment into
  # the systemd user session — set it explicitly using the %U UID specifier.
  systemd.user.services.gnome-keyring-env = {
    Unit = {
      Description = "Export GNOME_KEYRING_CONTROL into systemd user environment";
      Before = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user set-environment GNOME_KEYRING_CONTROL=/run/user/%U/keyring";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session-pre.target" ];
  };
}
