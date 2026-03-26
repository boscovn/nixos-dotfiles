{ ... }:
{
  imports = [ ./hyprland.nix ];
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
}
