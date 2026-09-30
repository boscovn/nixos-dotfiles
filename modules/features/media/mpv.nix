# mpv with thumbnails and MPRIS, as the default video player. Hardware decoding defaults to mpv's portable
# `auto-safe`; a host that knows what works sets programs.mpv.config.hwdec
# (and gpu-api) itself.
{
  homeManager.gui =
    { lib, pkgs, ... }:
    {
      programs.mpv = {
        enable = true;
        scripts = with pkgs.mpvScripts; [
          mpris
          mpv-cheatsheet-ng
          thumbfast
          thumbfast-vanilla-osc
        ];
        config = {
          save-position-on-quit = true;
          vo = "gpu-next";
          hwdec = lib.mkDefault "auto-safe";
        };
      };
      xdg.mimeApps.defaultApplications = lib.genAttrs [
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
      ] (_: [ "mpv.desktop" ]);
    };
}
