# The pre-dendritic configuration (hosts/ + modules/{nixos,home,stylix.nix}),
# plugged into the thinkpad unchanged while features move out of it one at a
# time. Deleted once empty.
{ inputs, ... }:
let
  inherit (inputs) nixpkgs;

  # Host data: hosts/defaults.nix overridden by hosts/<name>/host.nix.
  mkHost =
    name:
    (nixpkgs.lib.recursiveUpdate (import ../../hosts/defaults.nix) (
      import ../../hosts/${name}/host.nix
    ))
    // {
      hostname = name;
    };

  host = mkHost "thinkpad";
in
{
  hosts.thinkpad = {
    inherit (host) system;
    specialArgs = {
      inherit inputs host;
      inherit (host) hostname user;
    };
  };

  nixos.thinkpad.imports = [ ../../hosts/thinkpad ];

  homeManager.thinkpad.imports = [ ../home ];

  # Standalone Neovim, built straight from the same nixvim config used by
  # modules/home/nixvim, independent of home-manager/NixOS.
  # `nix run ~/.dotfiles#nvim` rebuilds/tests just the editor config.
  perSystem =
    { system, ... }:
    {
      packages.nvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs; };
        module = [
          { nixpkgs.source = nixpkgs; }
          ../home/nixvim/shared/config.nix
          ../home/nixvim/shared/keymaps.nix
        ];
      };
    };
}
