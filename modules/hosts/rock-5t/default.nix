# Home-manager-only host on a non-NixOS Linux distribution (also Ubuntu & co.
# on WSL). Created from templates/home (see modules/flake/new-host.nix); the
# host is named after this directory. Switch with `hms`.
let
  name = baseNameOf ./.;

  # miniforge's conda and mamba, inactive by default.
  condaInit = shell: ''
    __conda_setup="$("$HOME/miniforge3/bin/conda" shell.${shell} hook 2>/dev/null)"
    [ $? -eq 0 ] && eval "$__conda_setup"
    unset __conda_setup
    conda deactivate 2>/dev/null

    export MAMBA_EXE="$HOME/miniforge3/bin/mamba"
    export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell ${shell} --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
    [ $? -eq 0 ] && eval "$__mamba_setup"
    unset __mamba_setup
  '';
in
{
  hosts.${name} = {
    system = "aarch64-linux";
    nixos = false;
    # The image's default user.
    user = "radxa";
  };

  homeManager.${name} = {
    # The release this home was first set up with (by its earlier standalone
    # home-manager config); never change it.
    home.stateVersion = "24.11";
    # Desktop entries, XDG_DATA_DIRS and locale on a non-NixOS distribution.
    targets.genericLinux.enable = true;

    # Things installed outside Nix on this board: ~/.local/bin, npm's global
    # prefix, rustup's cargo, extra zsh completions and miniforge.
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.cargo/bin"
    ];
    programs.zsh.initContent = ''
      fpath+=~/.zsh/completions
      ${condaInit "zsh"}
    '';
    programs.bash.initExtra = condaInit "bash";
  };
}
