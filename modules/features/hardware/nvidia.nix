# Nvidia proprietary driver. The host picks the driver branch
# (hardware.nvidia.package) when `stable` doesn't support its GPU.
{
  nixos.nvidia =
    { config, lib, ... }:
    {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = true;
        open = lib.mkDefault false;
        powerManagement.enable = true;
      };
    };
}
