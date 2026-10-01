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

    # The presentation pointer is a transparent window the daemon makes
    # fullscreen on Qt's primary screen (the laptop panel). On Hyprland that
    # hides the windows behind it and blurs the wallpaper through it. Float
    # it over the focused monitor instead, untouched by blur and focus.
    wayland.windowManager.hyprland.settings.window_rule = [
      {
        name = "kdeconnect-presenter";
        match = {
          class = "^org\\.kde\\.kdeconnect\\.daemon$";
          title = "^KDE Connect Daemon$";
        };
        suppress_event = "fullscreen maximize";
        float = true;
        pin = true;
        move = "0 0";
        size = "monitor_w monitor_h";
        no_blur = true;
        no_shadow = true;
        no_anim = true;
        border_size = 0;
        rounding = 0;
        no_initial_focus = true;
        no_focus = true;
      }
    ];
  };
}
