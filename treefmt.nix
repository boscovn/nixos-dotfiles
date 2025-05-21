# treefmt.nix
{ pkgs, ... }:
{
  # used to find the project root
  projectRootFile = "flake.nix";
  # enable the terraform formatter
  programs.nixfmt.enable = true;
}
