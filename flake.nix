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

      mkSystem =
        {
          hostname,
          system ? "x86_64-linux",
          user ? "bosco",
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs hostname user; };
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
            stylix.nixosModules.stylix
            ./modules/nixos/common.nix
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user} = import ./modules/home;
              home-manager.extraSpecialArgs = { inherit inputs hostname user; };
            }
          ];
        };
    in
    {
      formatter = eachSystem (system: treefmtEval.${system}.config.build.wrapper);
      checks = eachSystem (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      nixosConfigurations = {
        thinkpad = mkSystem { hostname = "thinkpad"; };
        # Example: adding another machine is one line:
        # desktop = mkSystem { hostname = "desktop"; system = "x86_64-linux"; };
      };
    };
}
