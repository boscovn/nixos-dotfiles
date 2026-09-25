# Always-on layer: everything that makes sense in a terminal on any machine
# (Linux desktop, WSL, darwin). No GUI apps, no desktop-session plumbing.
{
  lib,
  pkgs,
  inputs,
  host,
  ...
}:
let
  # No graphical session to host a prompt on WSL/servers; macOS has its own.
  pinentry =
    if host.os == "darwin" then
      pkgs.pinentry_mac
    else if builtins.elem "desktop" host.profiles then
      pkgs.pinentry-gnome3
    else
      pkgs.pinentry-curses;
in
{
  imports = [
    ../shell
    ../nixvim
    ../tools.nix
  ];

  home.packages =
    with pkgs;
    [
      claude-code
      devenv
      jq
      nixfmt
      ouch
    ]
    ++ [ inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  programs.gh.enable = true;
  programs.gpg.enable = true;
  programs.yazi.enable = true;
  programs.yazi.shellWrapperName = "y";
  programs.git = {
    enable = true;
    settings = {
      user.name = "Bosco Vallejo-Nágera";
      user.email = "bosco@vallejonagera.xyz";
    };
  };

  # stylix themes every app it knows about by default, which on a terminal-only
  # host (WSL/darwin/server) generates config for GUI apps that are not even
  # installed (gtk, blender, vencord, ...). Only auto-enable with the desktop
  # profile; otherwise theme just the tools this profile provides.
  stylix.autoEnable = lib.mkDefault (builtins.elem "desktop" host.profiles);
  stylix.targets = {
    bat.enable = true;
    yazi.enable = true;
    starship.enable = true;
  };

  # HM's gpg-agent module is a systemd user service, so Linux only.
  services.gpg-agent = lib.mkIf (host.os == "linux") {
    enable = true;
    pinentry.package = pinentry;
  };
}
