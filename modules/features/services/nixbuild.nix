# Offload builds to nixbuild.net.
{ config, ... }:
let
  inherit (config.nixos) secrets;
in
{
  nixos.nixbuild =
    { config, ... }:
    {
      imports = [ secrets ];

      # Remote builds are run by the nix-daemon as root, so this goes in the
      # system-wide ssh_config. The key is dedicated to nixbuild.net, readable
      # only by root (sops-nix's default), and has no passphrase (the daemon
      # has no ssh-agent). It comes from the host's secrets.yaml
      # (`nixbuild-ssh-key`); for a new host:
      #   ssh-keygen -t ed25519 -N "" -C "nixbuild@<hostname>" -f key
      #   sops modules/hosts/<hostname>/secrets.yaml   # paste key as nixbuild-ssh-key: |
      # then add key.pub to the nixbuild.net account and delete both files.
      sops.secrets.nixbuild-ssh-key = { };
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
          ServerAliveInterval 60
          IdentitiesOnly yes
          IdentityFile ${config.sops.secrets.nixbuild-ssh-key.path}
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
              "ca-derivations"
              "kvm"
              "nixos-test"
            ];
          }
          {
            hostName = "eu.nixbuild.net";
            system = "aarch64-linux";
            maxJobs = 100;
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "ca-derivations"
              "kvm"
              "nixos-test"
            ];
          }
        ];
        # Let the builder fetch dependencies from binary caches itself instead
        # of uploading them from this machine.
        settings.builders-use-substitutes = true;
      };
    };
}
