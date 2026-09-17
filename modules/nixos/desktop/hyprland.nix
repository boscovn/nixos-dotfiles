{ ... }:
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
}
