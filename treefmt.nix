# treefmt.nix
{ pkgs, ... }:
{
  # used to find the project root
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
}
