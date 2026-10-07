# Offload builds to nixbuild.net.
{
  nixos.nixbuild = {
    # Remote builds are run by the nix-daemon as root, so this goes in the
    # system-wide ssh_config. The key is dedicated to nixbuild.net, readable
    # only by root, and has no passphrase (the daemon has no ssh-agent).
    # Not managed by Nix; create it once with:
    #   sudo install -d -m 700 /root/.ssh
    #   sudo ssh-keygen -t ed25519 -N "" -C "nixbuild@<hostname>" -f /root/.ssh/nixbuild_ed25519
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
