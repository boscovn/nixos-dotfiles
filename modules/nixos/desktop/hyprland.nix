{ ... }:
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
}
