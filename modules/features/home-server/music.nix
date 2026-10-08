# The music library (mpd.nix's music directory, also read by Jellyfin), owned
# by beets: `music-import DIR` splits CUE + single-file images into tracks
# (cue-split.py, Jellyfin needs one file per track) and imports DIR with
# beets, which tags from MusicBrainz and moves the albums into the library.
#
# The library lives in ~/mediamanager/data, shared with that Docker stack
# through the `media` group: setgid dirs and group-writable files, every
# writer running with umask 002. So do beets and cue-split; radxa's shell
# umask (022) would leave new files without group write.
{
  homeManager.homeServer =
    { config, pkgs, ... }:
    let
      library = config.services.mpd.musicDirectory;

      cue-split = pkgs.writeShellApplication {
        name = "cue-split";
        runtimeInputs = [ pkgs.unflac ];
        text = ''
          exec ${pkgs.python3}/bin/python3 ${./cue-split.py} \
            --originals ${dirOf library}/cue-originals "$@"
        '';
      };
    in
    {
      programs.beets = {
        enable = true;
        package = pkgs.symlinkJoin {
          name = "beets-umask-${pkgs.beets.version}";
          paths = [ pkgs.beets ];
          postBuild = ''
            rm $out/bin/beet
            cat >$out/bin/beet <<EOF
            #!${pkgs.runtimeShell}
            umask 002
            exec ${pkgs.beets}/bin/beet "\$@"
            EOF
            chmod +x $out/bin/beet
          '';
        };
        settings = {
          directory = library;
          import = {
            move = true;
            write = true;
            # Next to the library database (beets doesn't create the log's directory).
            log = "${config.xdg.configHome}/beets/import.log";
          };
          paths.default = "$albumartist/($year) $album%aunique{}/$track $title";
          # The MusicBrainz autotagger is a plugin, only on by default when
          # no plugins are listed.
          plugins = [
            "musicbrainz"
            "fetchart"
            "embedart"
          ];
        };
        # mpd rescans after imports.
        mpdIntegration.enableUpdate = true;
      };

      home.packages = [
        cue-split
        (pkgs.writeShellApplication {
          name = "music-import";
          runtimeInputs = [
            cue-split
            config.programs.beets.package
          ];
          text = ''
            umask 002
            # Images that couldn't be split are reported; import the rest.
            cue-split "$@" || true
            beet import "$@"
          '';
        })
      ];
    };
}
