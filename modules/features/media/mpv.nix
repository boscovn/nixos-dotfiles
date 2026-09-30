# mpv with thumbnails and MPRIS. Hardware decoding defaults to mpv's portable
# `auto-safe`; a host that knows what works sets programs.mpv.config.hwdec
# (and gpu-api) itself.
{
  homeManager.mpv =
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
    };
}
