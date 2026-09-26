{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # ... other inputs
    ashell.url = "github:MalpenZibo/ashell";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    stylix.url = "github:danth/stylix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      treefmt-nix,
      nixvim,
      stylix,
      ...
    }@inputs:
    let
      eachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      treefmtEval = eachSystem (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );

      # Host data: hosts/defaults.nix overridden by hosts/<name>/host.nix.
      # Passed to every NixOS and home-manager module as the `host` argument.
      mkHost =
        name:
        (nixpkgs.lib.recursiveUpdate (import ./hosts/defaults.nix) (import ./hosts/${name}/host.nix))
        // {
          hostname = name;
        };

      # Single source of truth for nixpkgs config, so `reb` and `hms` build the
      # same package set (they used to disagree on cudaSupport).
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
            {
              # Hyprland 0.56.1 requires glaze <8 (CMakeLists.txt: find_package(glaze 7...<8)),
              # but nixpkgs bumped glaze to 8.0.0, breaking the build. Pin glaze back to 7.8.3
              # until nixpkgs/Hyprland resolve the mismatch upstream.
              # nixpkgs.overlays = [
              #   (final: prev: {
              #     glaze = prev.glaze.overrideAttrs (old: {
              #       version = "7.8.3";
              #       src = prev.fetchFromGitHub {
              #         owner = "stephenberry";
              #         repo = "glaze";
              #         tag = "v7.8.3";
              #         hash = "sha256-WqtaZ3AVDs1oIfAVQuU63eg+0753LoYfv/pRyG9OMnM=";
              #       };
              #     });
              #   })
              # ];
            }
            { nixpkgs.config = nixpkgsConfig host; }
            stylix.nixosModules.stylix
            ./modules/nixos/common.nix
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./modules/home;
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
            ./modules/stylix.nix
            ./modules/home
          ];
        };
    in
    {
      formatter = eachSystem (system: treefmtEval.${system}.config.build.wrapper);
      checks = eachSystem (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      # Standalone Neovim, built straight from the same nixvim config used by
      # modules/home/nixvim, independent of home-manager/NixOS.
      # `nix run ~/.dotfiles#nvim` rebuilds/tests just the editor config.
      packages = eachSystem (system: {
        nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          module = [
            { nixpkgs.source = nixpkgs; }
            ./modules/home/nixvim/shared/config.nix
            ./modules/home/nixvim/shared/keymaps.nix
          ];
        };
      });

      nixosConfigurations = {
        thinkpad = mkSystem { hostname = "thinkpad"; };
        # Example: adding another machine is one line:
        # desktop = mkSystem { hostname = "desktop"; };  # + hosts/desktop/{default,host}.nix
      };

      # Standalone Home Manager, independent of nixos-rebuild.
      # `home-manager switch --flake ~/.dotfiles#bosco@thinkpad` (aliased `hms`)
      # applies user-space changes without a full system rebuild.
      homeConfigurations = {
        "bosco@thinkpad" = mkHome { hostname = "thinkpad"; };
      };
    };
}
