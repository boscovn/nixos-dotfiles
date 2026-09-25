{
  lib,
  pkgs,
  host,
  ...
}:
{
  config = lib.mkIf host.gpu.intel.enable {
    # Hardware video decode (VA-API/VDPAU) on the integrated GPU.
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
}
