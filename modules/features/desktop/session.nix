{
  homeManager.gui =
    { pkgs, ... }:
    {
      dotfiles.gui = true;
      fonts.fontconfig.enable = true;
      home.packages = with pkgs; [
        wl-clipboard
        grim
        slurp
      ];
      home.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
      };
      services.hyprpolkitagent.enable = true;
      services.swaync.enable = true;
      programs.fuzzel.enable = true;

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
    };

  nixos.gui = {
    hardware.graphics.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    # Required for the LUKS passphrase to get cached into the kernel keyring
    # during boot, which is what lets pam_gnome_keyring (greetd's
    # KeyringMode=shared) auto-unlock the login keyring under autologin
    # without it, gnome-keyring-daemon starts but the keyring stays locked.
    boot.tmp.cleanOnBoot = true;
    boot.plymouth.enable = true;
  };
}
