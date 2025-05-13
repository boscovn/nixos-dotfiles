{ config, pkgs, ... }:
{
  imports = [
    ./waybar.nix
    ./hypridle.nix
  ];
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  services.hyprpolkitagent.enable = true;
}
