# Turns each `hosts.<name>` into nixosConfigurations.<name> (home-manager
# embedded, `reb`) and homeConfigurations."<user>@<name>" (standalone, `hms`).
# Both use the same `homeManager.<name>` module, so they cannot drift.
{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (inputs) nixpkgs home-manager;
  inherit (config.my) user;

  # allowUnfree everywhere; a host adds or overrides via hosts.<name>.nixpkgsConfig.
  nixpkgsConfig = host: { allowUnfree = true; } // host.nixpkgsConfig;

  # Facts about the host that home-manager modules may need, as read-only
  # options, set for both the embedded and the standalone build.
  hostModule = name: host: { lib, ... }: {
    options.dotfiles = {
      hostname = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
      };
      nixos = lib.mkOption {
        type = lib.types.bool;
        readOnly = true;
        description = "Whether this host is a NixOS system (has `reb`).";
      };
    };
    config.dotfiles = {
      hostname = name;
      inherit (host) nixos;
    };
  };

  mkSystem =
    name: host:
    nixpkgs.lib.nixosSystem {
      inherit (host) system;
      inherit (host) specialArgs;
      modules = [
        {
          nixpkgs.config = nixpkgsConfig host;
          networking.hostName = name;
        }
        config.nixos.${name}
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${user}.imports = [
            (hostModule name host)
            config.homeManager.${name}
          ];
          home-manager.extraSpecialArgs = host.specialArgs;
        }
      ];
    };

  mkHome =
    name: host:
    home-manager.lib.homeManagerConfiguration {
      # Same config `useGlobalPkgs` shares with the NixOS-embedded build.
      pkgs = import nixpkgs {
        inherit (host) system;
        config = nixpkgsConfig host;
      };
      extraSpecialArgs = host.specialArgs;
      modules = config.standaloneHomeModules ++ [
        (hostModule name host)
        config.homeManager.${name}
      ];
    };
in
{
  options.standaloneHomeModules = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
    description = ''
      Home-manager modules only for standalone builds (`hms`), for things the
      NixOS side injects into embedded home-manager by itself (stylix).
    '';
  };

  options.hosts = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          system = lib.mkOption {
            type = lib.types.str;
            default = "x86_64-linux";
          };
          nixos = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Build a NixOS system for this host (false: standalone home-manager only, e.g. darwin or non-NixOS WSL).";
          };
          nixpkgsConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Extra nixpkgs config (on top of allowUnfree), shared by the NixOS and standalone home-manager builds, e.g. { cudaSupport = true; }.";
          };
          # Transitional: the legacy modules still expect these module args.
          specialArgs = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = lib.mapAttrs mkSystem (lib.filterAttrs (_: host: host.nixos) config.hosts);
    homeConfigurations = lib.mapAttrs' (
      name: host: lib.nameValuePair "${user}@${name}" (mkHome name host)
    ) config.hosts;
  };
}
