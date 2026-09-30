# Default apps for images (imv) and video (mpv).
{ lib, ... }:
let
  videoTypes = [
    "video/mp4"
    "video/x-m4v"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/avi"
    "video/mpeg"
    "video/ogg"
    "video/x-flv"
    "video/x-ms-wmv"
    "video/3gpp"
    "video/mp2t"
  ];
  imageTypes = [
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
  ];
  toApp = app: types: lib.genAttrs types (_: app);
in
{
  xdg.mimeApps.defaultApplications =
    toApp [ "mpv.desktop" ] videoTypes // toApp [ "imv.desktop" ] imageTypes;
}
