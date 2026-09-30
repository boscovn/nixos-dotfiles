# Hardware video decode (VA-API/VDPAU) on an Intel integrated GPU.
{
  nixos.intel-graphics =
    { pkgs, ... }:
    {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
    };
}
