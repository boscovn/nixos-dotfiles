# Diun on the media server: every 6 hours, checks the running containers'
# images (Docker socket; radxa is in the docker group) for newer version tags
# and publishes them to the self-hosted ntfy (token from this host's
# secrets.yaml). Run once per timer tick: with no watch.schedule, `diun serve`
# checks once and exits. Its database of tags already seen is kept in
# ~/.local/state/diun, so each new tag notifies once; the first run only
# records them (firstCheckNotif).
#
# Only plain x.y.z / vx.y.z tags are watched, newest 5 by semver (the cap keeps
# Docker Hub's rate limit from cutting the first run short, after which old
# tags would notify as new). Images tagged otherwise (linuxserver's
# x.y.z.w-lsN, immich's postgres) match none and are skipped.
let
  name = baseNameOf ./.;
in
{
  homeManager.${name} =
    { config, pkgs, ... }:
    let
      stateDir = "${config.xdg.stateHome}/diun";
      settings = {
        db.path = "${stateDir}/diun.db";
        watch = {
          workers = 4;
          firstCheckNotif = false;
        };
        defaults = {
          watchRepo = true;
          sortTags = "semver";
          maxTags = 5;
          includeTags = [ "^v?\\d+\\.\\d+\\.\\d+$" ];
        };
        providers.docker.watchByDefault = true;
        notif.ntfy = {
          endpoint = "https://ntfy.vallejonagera.xyz";
          topic = "diun";
          tokenFile = config.sops.secrets.ntfy-token.path;
          tags = [ "whale" ];
          templateTitle = "{{ .Entry.Metadata.ctn_names }}: {{ .Entry.Image.Tag }}";
          templateBody = "{{ .Entry.Image }} is available.";
        };
      };
    in
    {
      sops.secrets.ntfy-token = { };

      systemd.user.services.diun = {
        Unit = {
          Description = "Check the running containers' images for new tags";
          After = [
            "network-online.target"
            "sops-nix.service"
          ];
          Requires = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          # StateDirectory= would be ~/.config on this systemd (252), and
          # diun doesn't create the database's directory.
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${stateDir}";
          ExecStart = "${pkgs.diun}/bin/diun serve --config ${
            (pkgs.formats.yaml { }).generate "diun.yml" settings
          } --log-nocolor";
        };
      };

      systemd.user.timers.diun = {
        Unit.Description = "Check the running containers' images for new tags";
        Timer = {
          OnCalendar = "00/6:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
