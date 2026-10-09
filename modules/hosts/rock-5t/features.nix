# What this host runs: importing a feature enables it.
{ config, ... }:
let
  name = baseNameOf ./.;
  slots = config;
in
{
  homeManager.${name}.imports = with slots.homeManager; [
    base
    homeServer
    secrets
  ];
}
