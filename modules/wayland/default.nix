{ config, pkgs, ... }:
{
  imports = [
    ./waybar.nix
    ./hypridle.nix
  ];
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
  };
  services.hyprpolkitagent.enable = true;
  services.swaync.enable = true;
  programs.fuzzel.enable = true;
}
