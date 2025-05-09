{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
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
  programs.mpv = {
    enable = true;
    config = {
      save-position-on-quit = true;

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
        "pulseaudio"
        "battery"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
      };
    };
    "pulseaudio" = {
      "format" = "{volume}% {icon}";
      "format-bluetooth" = "{volume}% {icon}";
      "format-muted" = "";
      "format-icons" = {
        "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
        "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
        "headphones" = "";
        "handsfree" = "";
        "headset" = "";
        "phone" = "";
        "phone-muted" = "";
        "portable" = "";
        "car" = "";
        "default" = [
          ""
          ""
        ];
      };
      "scroll-step" = 1;
      "on-click" = "${pkgs.pavucontrol}";
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
  programs.nixvim = {
    enable = true;
    globals.mapleader = true;
    plugins = {
      oil.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
    };
  };
}
