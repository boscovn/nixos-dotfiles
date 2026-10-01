# ThinkPad: Intel UHD 620 + Nvidia MX150 (PRIME offload).
{ inputs, ... }:
{
  hosts.thinkpad = { };

  nixos.thinkpad =
    { config, ... }:
    {
      # Hardware from the nixos-facter report; disks from disko.
      imports = [
        inputs.disko.nixosModules.disko
        ./_disko.nix
      ];
      hardware.facter.reportPath = ./facter.json;
      # Facter would load the detected GPU drivers (i915, nvidia) in the initrd
      # (early KMS); kept out as before.
      hardware.facter.detected.boot.graphics.kernelModules = [ ];
      # Facter would set useDHCP on every detected interface, starting dhcpcd
      # alongside the existing network setup.
      hardware.facter.detected.dhcp.enable = false;

      system.stateVersion = "24.05";

      hardware.nvidia = {
        # Pascal (MX150) support ended with the 580 driver branch.
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        prime = {
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };

  homeManager.thinkpad =
    { config, lib, ... }:
    {
      home.stateVersion = "24.05";

      dotfiles.terminal = rec {
        package = config.programs.ghostty.package;
        newWindow = "${lib.getExe package} +new-window";
      };

      programs.mpv.config = {
        # Decode on the Intel iGPU: the MX150 exposes no usable NVDEC (ffmpeg
        # -hwaccel cuda: "Hardware is lacking required capabilities" for H.264,
        # HEVC and VP9), and the iGPU avoids waking the dGPU.
        hwdec = "vaapi";
        gpu-api = "opengl";
      };
    };
}
