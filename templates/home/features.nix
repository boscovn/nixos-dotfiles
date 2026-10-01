# What this host runs: importing a feature enables it.
{ config, ... }:
let
  name = baseNameOf ./.;
in
{
  homeManager.${name}.imports = with config.homeManager; [ base ];
}
