# Catppuccin theme via stylix, for the system and home-manager.
{ inputs, ... }:
let
  theme =
    { pkgs, ... }:
    {
      stylix.enable = true;
      # stylix.targets.nixvim.enable = false;
      # stylix.targets.rofi.enable = false;
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      stylix.opacity.terminal = 0.8;
      stylix.fonts.monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCodeNerdFont";
      };
      stylix.image = ../../gnus.JPG;
    };
in
{
  # On NixOS, stylix injects its home-manager module into embedded
  # home-manager itself (homeManagerIntegration.autoImport), copying these
  # settings and disabling overlays there, since embedded home-manager uses the
  # system's pkgs.
  nixos.base.imports = [
    inputs.stylix.nixosModules.stylix
    theme
  ];

  # Standalone home-manager (`hms`) has no NixOS side to do that injection.
  standaloneHomeModules = [
    inputs.stylix.homeModules.stylix
    theme
  ];
}
