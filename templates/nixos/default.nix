# NixOS host. Created from templates/nixos (see modules/flake/new-host.nix);
# the host is named after this directory.
{ inputs, ... }:
let
  name = baseNameOf ./.;
in
{
  hosts.${name}.system = "@system@";

  nixos.${name} = {
    # Hardware from the nixos-facter report; disks from disko.
    imports = [
      inputs.disko.nixosModules.disko
      ./_disko.nix
    ];
    hardware.facter.reportPath = ./facter.json;

    # The NixOS release this host was installed with; never change it.
    system.stateVersion = "@stateVersion@";
  };

  homeManager.${name}.home.stateVersion = "@stateVersion@";
}
