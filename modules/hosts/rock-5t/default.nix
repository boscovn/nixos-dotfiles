# Home-manager-only host on a non-NixOS Linux distribution (also Ubuntu & co.
# on WSL). Created from templates/home (see modules/flake/new-host.nix); the
# host is named after this directory. Switch with `hms`.
let
  name = baseNameOf ./.;
in
{
  hosts.${name} = {
    system = "aarch64-linux";
    nixos = false;
    # The image's default user.
    user = "radxa";
  };

  homeManager.${name} =
    { pkgs, ... }:
    {
      # The release this home was first set up with (by its earlier standalone
      # home-manager config); never change it.
      home.stateVersion = "24.11";
      # Desktop entries, XDG_DATA_DIRS and locale on a non-NixOS distribution.
      targets.genericLinux.enable = true;

      # Installed outside Nix on this board: ~/.local/bin and rustup's cargo.
      home.sessionPath = [
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
      ];
      # Completions for Docker (from Docker's apt repository).
      programs.zsh.initContent = "fpath+=~/.zsh/completions";

      # Secrets decrypt with this host's own age key
      # (~/.config/sops/age/keys.txt, made here with age-keygen; .sops.yaml).
      sops.defaultSopsFile = ./secrets.yaml;

      home.packages = with pkgs; [
        _7zz
        btop
        ffmpeg
        fzf
        imagemagick
        mkcert
        sqlite
      ];
    };
}
