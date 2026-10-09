# Diun on the media server: every 6 hours, checks the images pinned in
# ~/mediamanager's compose.lock.yaml for newer tags and publishes them to the
# self-hosted ntfy (token from this host's secrets.yaml). One-shot runs from a
# timer: with no watch.schedule, diun checks once and exits. Its database of
# tags already seen is kept in ~/.local/state/diun, so each new tag notifies
# once; the first run only records them (firstCheckNotif).
let
  name = baseNameOf ./.;
in
{
  homeManager.${name} =
    { config, pkgs, ... }:
    let
      stateDir = "${config.xdg.stateHome}/diun";
      lockfile = "${config.home.homeDirectory}/mediamanager/compose.lock.yaml";

      diun-images = pkgs.writers.writePython3Bin "diun-images" {
        libraries = [ pkgs.python3Packages.pyyaml ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./diun-images.py);

      settings = {
        db.path = "${stateDir}/diun.db";
        watch = {
          workers = 4;
          firstCheckNotif = false;
        };
        providers.file.filename = "${stateDir}/images.yml";
        notif.ntfy = {
          endpoint = "https://ntfy.vallejonagera.xyz";
          topic = "diun";
          tokenFile = config.sops.secrets.ntfy-token.path;
          tags = [ "whale" ];
          templateTitle = "{{ .Entry.Metadata.service }}: {{ .Entry.Image.Tag }}";
          templateBody = "{{ .Entry.Image }} is available (running {{ .Entry.Metadata.running }}).";
        };
      };
    in
    {
      sops.secrets.ntfy-token = { };

      systemd.user.services.diun = {
        Unit = {
          Description = "Check the media server's images for new tags";
          After = [
            "network-online.target"
            "sops-nix.service"
          ];
          Requires = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${stateDir}"
            "${diun-images}/bin/diun-images ${lockfile} ${stateDir}/images.yml"
          ];
          ExecStart = builtins.concatStringsSep " " [
            "${pkgs.diun}/bin/diun serve"
            "--config ${(pkgs.formats.yaml { }).generate "diun.yml" settings}"
            # Only for the duration of a run, but on loopback, not every interface.
            "--grpc-authority 127.0.0.1:42286"
            "--log-nocolor"
          ];
        };
      };

      systemd.user.timers.diun = {
        Unit.Description = "Check the media server's images for new tags";
        Timer = {
          OnCalendar = "00/6:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
