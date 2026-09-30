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
      virtualisation.docker.enableOnBoot = f.dockerOnBoot;
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

    (lib.mkIf f.nixbuild {
      # Remote builds are run by the nix-daemon as root, so this goes in the
      # system-wide ssh_config. The key is dedicated to nixbuild.net, readable
      # only by root, and has no passphrase (the daemon has no ssh-agent).
      # Not managed by Nix; create it once with:
      #   sudo install -d -m 700 /root/.ssh
      #   sudo ssh-keygen -t ed25519 -N "" -C "nixbuild@${host.hostname}" -f /root/.ssh/nixbuild_ed25519
      # then add /root/.ssh/nixbuild_ed25519.pub to the nixbuild.net account.
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
          ServerAliveInterval 60
          IdentitiesOnly yes
          IdentityFile /root/.ssh/nixbuild_ed25519
      '';
      programs.ssh.knownHosts.nixbuild = {
        hostNames = [ "eu.nixbuild.net" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
      };
      nix = {
        distributedBuilds = true;
        buildMachines = [
          {
            hostName = "eu.nixbuild.net";
            system = "x86_64-linux";
            maxJobs = 100;
            supportedFeatures = [
              "benchmark"
              "big-parallel"
            ];
          }
        ];
        # Let the builder fetch dependencies from binary caches itself instead
        # of uploading them from this machine.
        settings.builders-use-substitutes = true;
      };
    })
  ];
}
