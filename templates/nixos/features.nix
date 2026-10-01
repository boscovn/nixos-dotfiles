# What this host runs: importing a feature enables it.
{ config, ... }:
let
  name = baseNameOf ./.;
in
{
  nixos.${name}.imports = with config.nixos; [ base ];
  homeManager.${name}.imports = with config.homeManager; [ base ];
}
