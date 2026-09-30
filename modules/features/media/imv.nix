# imv as the default image viewer.
{
  homeManager.gui =
    { lib, ... }:
    {
      programs.imv.enable = true;
      xdg.mimeApps.defaultApplications = lib.genAttrs [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
        "image/avif"
        "image/heif"
        "image/jxl"
        "image/qoi"
      ] (_: [ "imv.desktop" ]);
    };
}
