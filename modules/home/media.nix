# Default apps for images (imv) and video (mpv), plus a desktop-entry override
# so mpv opened from file managers/browsers also runs on the discrete GPU.
{
  config,
  lib,
  pkgs,
  host,
  ...
}:
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

  # The shell alias `mpv = nvidia-offload mpv` only covers terminals; anything
  # launched through a desktop entry never sees it. Same entry as the package's
  # own, with just the Exec line prefixed.
  offloadMpv = pkgs.runCommand "mpv.desktop" { } ''
    sed 's|^Exec=mpv |Exec=nvidia-offload mpv |' \
      ${config.programs.mpv.finalPackage}/share/applications/mpv.desktop > $out
    grep -q '^Exec=nvidia-offload mpv ' $out
  '';
in
{
  xdg.mimeApps.defaultApplications =
    toApp [ "mpv.desktop" ] videoTypes // toApp [ "imv.desktop" ] imageTypes;

  # ~/.local/share/applications takes precedence over the package's entry of the
  # same name, so the existing mpv.desktop associations keep working.
  xdg.dataFile."applications/mpv.desktop" = lib.mkIf host.gpu.nvidia.prime.enable {
    source = offloadMpv;
  };
}
