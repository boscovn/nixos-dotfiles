{ config, pkgs, ... }:
{
  imports = [
    ./waybar.nix
    ./hypridle.nix
  ];
}
