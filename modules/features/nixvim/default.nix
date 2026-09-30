# Neovim via nixvim: the home-manager module and a standalone package
# (`nix run ~/.dotfiles#nvim`, used by the `nnvim` shell function), both built
# from the same _shared/ config.
{ inputs, ... }:
let
  shared = [
    ./_shared/config.nix
    ./_shared/keymaps.nix
  ];
in
{
  homeManager.base = {
    imports = [ inputs.nixvim.homeModules.nixvim ];
    programs.nixvim = {
      enable = true;
      nixpkgs.source = inputs.nixpkgs;
      imports = shared;
    };
  };

  perSystem =
    { system, ... }:
    {
      packages.nvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs; };
        module = [ { nixpkgs.source = inputs.nixpkgs; } ] ++ shared;
      };
    };
}
