# Spotify Connect speaker ("rock-5t" in the Spotify apps), through the
# distribution's PipeWire (pulseaudio backend).
{
  homeManager.homeServer =
    { config, ... }:
    {
      services.spotifyd = {
        enable = true;
        settings.global = {
          backend = "pulseaudio";
          device_name = config.dotfiles.hostname;
          bitrate = 320;
          cache_path = "${config.xdg.cacheHome}/spotifyd";
          volume_normalisation = true;
          normalisation_pregain = -10;
        };
      };
    };
}
