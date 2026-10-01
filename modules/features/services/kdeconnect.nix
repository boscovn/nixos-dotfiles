# KDE Connect: the daemon and its tray indicator run as home-manager user
# services; NixOS opens the firewall and provides the RemoteDesktop portal
# backend. A host imports both nixos.kdeconnect and homeManager.kdeconnect.
{ inputs, ... }:
{
  nixos.kdeconnect =
    { config, ... }:
    {
      imports = [ inputs.hypr-kdeconnect-fix.nixosModules.default ];
      # Opens 1714-1764 TCP/UDP; the package comes from home-manager.
      programs.kdeconnect = {
        enable = true;
        package = null;
      };
      # RemoteDesktop portal backend so KDE Connect's remote input works on
      # Hyprland; routes RemoteDesktop in xdg.portal.config.hyprland, whose
      # other entries are in hyprland.nix. Stays on NixOS: home-manager's
      # xdg.portal would replace the system's portal directory.
      services.hypr-kdeconnect-fix.enable = config.programs.hyprland.enable;
    };

  homeManager.kdeconnect = {
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
    # The package's XDG autostart entry would start a second kdeconnectd
    # (UWSM runs autostart entries) racing the user service; hide it.
    xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
