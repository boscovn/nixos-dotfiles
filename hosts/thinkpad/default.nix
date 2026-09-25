{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hardware/nvidia.nix
    # Paused: face match kept coming back "no match" (see howdy.nix).
    # ../../modules/nixos/hardware/howdy.nix
  ];

  networking.hostName = "thinkpad";

  environment.systemPackages = with pkgs; [
    android-tools
    v4l-utils
  ];
}
