# User tooling that used to live in NixOS environment.systemPackages. Prefer a
# programs.<name>.enable module when home-manager has one (config/theming/shell
# integration for free); the rest are plain packages. Not available to
# root/sudo sessions, by design.
{ pkgs, ... }:
{
  programs = {
    bat.enable = true;
    fd.enable = true;
    firefox.enable = true;
    foot.enable = true;
    go.enable = true;
    ripgrep.enable = true;
  };

  home.packages = with pkgs; [
    android-tools
    delve
    gopass
    gopass-jsonapi
    gopls
    libva-utils
    opensc
    pcsc-tools
    trashy
    usbutils
    v4l-utils
    wget
  ];
}
