# Secrets with sops-nix: encrypted in the repo, decrypted at activation to
# /run/secrets (NixOS) or $XDG_RUNTIME_DIR/secrets (home-manager). Recipients
# are in .sops.yaml; a host's own secrets go in modules/hosts/<name>/secrets.yaml
# (its sops.defaultSopsFile). Features that need a secret import nixos.secrets
# themselves and declare it (`sops.secrets.<name>`).
#
# NixOS hosts decrypt with their ssh host key (needs nixos.ssh, which creates
# it); home-manager with an age key at ~/.config/sops/age/keys.txt, placed by
# hand. Edit with `sops modules/hosts/<name>/secrets.yaml`; after changing
# .sops.yaml's recipients, `sops updatekeys <file>`.
{ inputs, ... }:
{
  nixos.secrets = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  homeManager.secrets =
    { config, pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
      sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      home.packages = with pkgs; [
        sops
        ssh-to-age
      ];
    };
}
