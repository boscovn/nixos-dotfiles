{ config, pkgs, ... }:

{
  imports = [ ./hyprland.nix ];
  # services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
}
