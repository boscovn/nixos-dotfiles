{
  config,
  pkgs,
  inputs,
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
      reb = "sudo nixos-rebuild switch --flake ~/.dotfiles#thinkpad";
      ls = "${pkgs.eza}/bin/eza";
    };
  };
  programs.bash = {
    enable = true;
  };
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };
}
