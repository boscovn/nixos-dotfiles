# What the thinkpad runs: importing a feature enables it.
{ config, ... }:
{
  nixos.thinkpad.imports = with config.nixos; [
    base
    gui
    nvidia
    nvidia-prime
    cuda
    intel-graphics
    laptop
    bluetooth
    docker
    gaming
    kdeconnect
    ssh
    nixbuild
  ];

  homeManager.thinkpad.imports = with config.homeManager; [
    mpv
  ];
}
