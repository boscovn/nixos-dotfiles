{ inputs, ... }:
{
  nixos.kdeconnect =
    { config, ... }:
    {
      imports = [ inputs.hypr-kdeconnect-fix.nixosModules.default ];
      programs.kdeconnect.enable = true;
      # RemoteDesktop portal backend so KDE Connect's remote input works on
      # Hyprland; routes RemoteDesktop in xdg.portal.config.hyprland, whose
      # other entries are in hyprland.nix.
      services.hypr-kdeconnect-fix.enable = config.programs.hyprland.enable;
    };
}
