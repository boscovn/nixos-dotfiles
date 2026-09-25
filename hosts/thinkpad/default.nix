{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/hardware/howdy.nix
  ];

  networking.hostName = "thinkpad";

  environment.systemPackages = with pkgs; [
    android-tools
    v4l-utils
  ];
}
