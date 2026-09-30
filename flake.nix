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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    stylix.url = "github:danth/stylix";
  };

  # Every .nix file under modules/ is a flake-parts module (import-tree);
  # paths containing `/_` are skipped. See CLAUDE.md.
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # modules/{nixos,home,stylix.nix} are the legacy tree, not flake-parts
        # modules; they are wired in by modules/flake/legacy.nix. (The regex
        # is matched against the path relative to ./modules.)
        ((inputs.import-tree.matchNot "/((nixos|home)/.*|stylix\\.nix)") ./modules)
      ];
    };
}
