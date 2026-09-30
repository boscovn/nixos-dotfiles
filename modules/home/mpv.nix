# mpv: scripts and playback config. Hardware decoding comes from host data
# (host.gpu.video, see hosts/defaults.nix) since what works differs per GPU.
{
  lib,
  pkgs,
  host,
  ...
}:
let
  video = host.gpu.video;
in
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
      inherit (video) hwdec;
    }
    // lib.optionalAttrs (video.api != null) {
      gpu-api = video.api;
    };
  };
}
