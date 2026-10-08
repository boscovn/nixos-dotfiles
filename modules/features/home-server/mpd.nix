# Music Player Daemon over the music library that mediamanager fills, playing
# through the distribution's PipeWire (pulse output, like spotifyd). Listens on
# all interfaces on MPD's default port (6600/tcp), which must be open in the
# firewall (ufw on the rock-5t) for clients on other machines.
{
  homeManager.homeServer =
    { config, ... }:
    {
      services.mpd = {
        enable = true;
        musicDirectory = "${config.home.homeDirectory}/mediamanager/data/music";
        network.listenAddress = "any";
        extraConfig = ''
          audio_output {
            type "pulse"
            name "PipeWire"
          }
        '';
      };
    };
}
