{ pkgs, ... }:
{
  stylix.enable = true;
  # stylix.targets.nixvim.enable = false;
  stylix.targets.rofi.enable = false;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.opacity.terminal = 0.8;
  stylix.fonts.monospace = {
    package = pkgs.nerd-fonts.fira-code;
    name = "FiraCodeNerdFont";
  };
  stylix.image = ./../gnus.JPG;
}
