{ inputs, ... }:
{
  imports = [ inputs.nixvim.homeModules.nixvim ];
  programs.nixvim = {
    enable = true;
    nixpkgs.source = inputs.nixpkgs;
    imports = [
      ./shared/config.nix
      ./shared/keymaps.nix
    ];
  };
}
