{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./modules/wayland
    ./modules/nixvim
    ./modules/shell
    ./modules/email
  ];
  home.username = "bosco";
  home.homeDirectory = "/home/bosco";
  home.stateVersion = "24.05";
  home.packages = with pkgs; [ gcr ];
  programs.gh.enable = true;
  programs.mpv = {
    enable = true;
    config = {
      save-position-on-quit = true;

    };
  };
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  programs.git = {
    enable = true;
    userName = "Bosco Vallejo-Nágera";
    userEmail = "bosco@vallejonagera.xyz";
  };
}
