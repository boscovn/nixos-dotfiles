{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    # Paused: face match kept coming back "no match" (see howdy.nix).
    # ../../modules/nixos/hardware/howdy.nix
  ];

  networking.hostName = "thinkpad";
}
