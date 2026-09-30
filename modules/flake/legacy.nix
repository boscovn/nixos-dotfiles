# The pre-dendritic configuration (hosts/ + modules/{nixos,home,stylix.nix}),
# wired unchanged while features move out of it one at a time.
{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager stylix;

  # Host data: hosts/defaults.nix overridden by hosts/<name>/host.nix.
  # Passed to every NixOS and home-manager module as the `host` argument.
  mkHost =
    name:
    (nixpkgs.lib.recursiveUpdate (import ../../hosts/defaults.nix) (
      import ../../hosts/${name}/host.nix
    ))
    // {
      hostname = name;
    };

  # Single source of truth for nixpkgs config, so `reb` and `hms` build the
  # same package set.
  nixpkgsConfig =
    host:
    {
      allowUnfree = true;
    }
    // nixpkgs.lib.optionalAttrs (host.gpu.nvidia.enable && host.gpu.nvidia.globalCudaSupport) {
      cudaSupport = true;
    };

  mkSystem =
    { hostname }:
    let
      host = mkHost hostname;
      inherit (host) user;
    in
    nixpkgs.lib.nixosSystem {
      inherit (host) system;
      specialArgs = {
        inherit
          inputs
          host
          hostname
          user
          ;
      };
      modules = [
        { nixpkgs.config = nixpkgsConfig host; }
        stylix.nixosModules.stylix
        ../nixos/common.nix
        ../../hosts/${hostname}
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user} = import ../home;
          home-manager.extraSpecialArgs = {
            inherit
              inputs
              host
              hostname
              user
              ;
          };
        }
      ];
    };

  mkHome =
    { hostname }:
    let
      host = mkHost hostname;
      inherit (host) user;
    in
    home-manager.lib.homeManagerConfiguration {
      # Same config `useGlobalPkgs` shares with the NixOS-embedded build.
      pkgs = import nixpkgs {
        inherit (host) system;
        config = nixpkgsConfig host;
      };
      extraSpecialArgs = {
        inherit
          inputs
          host
          hostname
          user
          ;
      };
      modules = [
        stylix.homeModules.stylix
        ../stylix.nix
        ../home
      ];
    };
in
{
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

  flake = {
    nixosConfigurations.thinkpad = mkSystem { hostname = "thinkpad"; };
    # `home-manager switch --flake ~/.dotfiles#bosco@thinkpad` (aliased `hms`).
    homeConfigurations."bosco@thinkpad" = mkHome { hostname = "thinkpad"; };
  };
}
