# Spotify Connect speaker ("rock-5t" in the Spotify apps), through the
# distribution's PipeWire (pulseaudio backend). No account is configured: a
# Premium account logs it in over zeroconf from the app (the login is then
# cached in ~/.cache/spotifyd). Zeroconf needs mDNS (5353/udp) and the
# zeroconf port below (tcp) open in the firewall (ufw on the rock-5t).
{
  homeManager.homeServer =
    { config, ... }:
    {
      services.spotifyd = {
        enable = true;
        settings.global = {
          backend = "pulseaudio";
          device_name = config.dotfiles.hostname;
          # Fixed so the firewall can allow it (random by default).
          zeroconf_port = 4070;
          bitrate = 320;
          cache_path = "${config.xdg.cacheHome}/spotifyd";
          volume_normalisation = true;
        };
      };
    };
}
