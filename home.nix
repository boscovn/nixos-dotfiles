{ config, pkgs, ... }:
{
  home.username = "bosco";
  home.homeDirectory = "/home/bosco";
  home.stateVersion = "24.05";
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.size = 10000;
    shellAliases = {
      reb = "sudo nixos-rebuild switch --flake ~/.dotfiles#thinkpad";
    };
  };
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.waybar.enable = true;
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
        "eDP-1"
        "HDMI-A-1"
      ];
      modules-left = [
        "hyprland/workspaces"
        "hyprland/mode"
        "wlr/taskbar"
      ];
      modules-center = [
        "hyprland/window"
      ];
      modules-right = [
        "temperature"
        "battery"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
      };
    };
  };
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  programs.git = {
    enable = true;
    userName = "Bosco Vallejo-Nágera";
    userEmail = "bosco@vallejonagera.xyz";
  };
}
