{ config, pkgs, ... }:

{
  imports = [ ./hyprland.nix ];
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
}
