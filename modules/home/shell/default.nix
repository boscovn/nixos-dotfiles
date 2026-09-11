{
  pkgs,
  hostname,
  user,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
    shellAliases = {
      reb = "sudo nixos-rebuild switch --flake ~/.dotfiles#${hostname} --impure";
      hms = "home-manager switch --flake ~/.dotfiles#${user}@${hostname}";
      nnvim = "nix run ~/.dotfiles#nvim";
      ls = "${pkgs.eza}/bin/eza";
      mpv = "nvidia-offload mpv";
    };
  };
  programs.bash = {
    enable = true;
    shellAliases = {
      reb = "sudo nixos-rebuild switch --flake ~/.dotfiles#${hostname} --impure";
      hms = "home-manager switch --flake ~/.dotfiles#${user}@${hostname}";
      nnvim = "nix run ~/.dotfiles#nvim";
    };
  };
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
