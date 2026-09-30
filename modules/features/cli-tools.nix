# Portable CLI tooling. Prefer a programs.<name>.enable module when
# home-manager has one (config/theming/shell integration for free); the rest are
# plain packages. Desktop/hardware tools live in the gui bundle. Not available
# to root/sudo sessions, by design.
{ inputs, ... }:
{
  homeManager.base =
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
        yazi = {
          enable = true;
          shellWrapperName = "y";
        };
      };

      home.packages =
        with pkgs;
        [
          claude-code
          delve
          devenv
          gopass
          gopls
          nixd
          jq
          nixfmt
          opensc
          ouch
          pcsc-tools
          wget
          inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
        ]
        # trashy is Linux-only (freedesktop trash spec).
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.trashy ];
    };
}
