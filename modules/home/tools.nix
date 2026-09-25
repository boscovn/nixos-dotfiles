# Portable CLI tooling (part of the core profile). Prefer a programs.<name>.enable
# module when home-manager has one (config/theming/shell integration for free);
# the rest are plain packages. Linux desktop/hardware tools live in
# profiles/desktop.nix. Not available to root/sudo sessions, by design.
{ lib, pkgs, ... }:
{
  programs = {
    bat.enable = true;
    fd.enable = true;
    go.enable = true;
    # Builds the mandb index so `man -k`/apropos work (Telescope man_pages,
    # :Man completion); off by default, so `man -k .` finds nothing.
    man.generateCaches = true;
    ripgrep.enable = true;
  };

  home.packages =
    with pkgs;
    [
      delve
      gopass
      gopls
      opensc
      pcsc-tools
      wget
    ]
    # trashy is Linux-only (freedesktop trash spec).
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.trashy ];
}
