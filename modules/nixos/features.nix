# Optional system features, each switched by host.features.<name> in
# hosts/<name>/host.nix (defaults in hosts/defaults.nix).
{
  lib,
  host,
  ...
}:
let
  f = host.features;
in
{
  config = lib.mkMerge [
    (lib.mkIf f.laptop {
      services.upower.enable = true;
      services.tlp = {
        enable = true;
        settings.USB_AUTOSUSPEND = 1;
      };
      # Keep running with the lid closed (docked / external display use).
      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    })

    (lib.mkIf f.bluetooth {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    })

    (lib.mkIf f.docker {
      virtualisation.docker.enable = true;
      virtualisation.docker.enableOnBoot = false;
      users.users.${host.user}.extraGroups = [ "docker" ];
    })

    (lib.mkIf f.gaming {
      programs.steam.enable = true;
    })

    (lib.mkIf f.kdeconnect {
      programs.kdeconnect.enable = true;
    })

    (lib.mkIf f.ssh {
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
      networking.firewall.allowedTCPPorts = [ 22 ];
    })
  ];
}
