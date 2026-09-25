{ pkgs, ... }:
{
  imports = [
    # ./waybar.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprlock.nix
    # ./niri.nix
    ./ashell.nix
    # ./quickshell.nix

  ];
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
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };
  # Dead keys (´ + vowel on the es layout) don't work through ghostty's GTK
  # input-method path here; GTK's built-in simple IM does. Scoped to ghostty's
  # service rather than session-wide so other GTK apps are unaffected.
  # Separate drop-in because programs.ghostty owns the unit and its overrides.conf.
  xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/gtk-im.conf".text = ''
    [Service]
    Environment=GTK_IM_MODULE=simple
  '';
}
