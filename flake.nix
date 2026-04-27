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
