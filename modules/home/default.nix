{
  config,
  pkgs,
  inputs,
  user,
  ...
}:
{
  imports = [
    ./wayland
    ./nixvim
    ./shell
    ./email
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "24.05";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
    };
  };

  home.packages = with pkgs; [
    claude-code
    corefonts
    devenv
    gcr
    gemini-cli
    jq
    kdePackages.dolphin
    liberation_ttf
    onlyoffice-desktopeditors
    ouch
    telegram-desktop
    vista-fonts
  ];

  fonts.fontconfig.enable = true;
  programs.gh.enable = true;
  programs.zathura.enable = true;
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
    config = {
      save-position-on-quit = true;
    };
  };
  programs.gpg.enable = true;
  programs.imv.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
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
  programs.yazi.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Bosco Vallejo-Nágera";
      user.email = "bosco@vallejonagera.xyz";
    };
  };
}
