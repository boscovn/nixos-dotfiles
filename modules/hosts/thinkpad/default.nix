# ThinkPad: Intel UHD 620 + Nvidia MX150 (PRIME offload).
{ config, ... }:
{
  nixos.thinkpad.imports = with config.nixos; [
    laptop
    bluetooth
    docker
    gaming
    kdeconnect
    ssh
    nixbuild
  ];
}
