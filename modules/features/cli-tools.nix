# Portable CLI tooling. Prefer a programs.<name>.enable module when
# home-manager has one (config/theming/shell integration for free); the rest are
# plain packages. Desktop/hardware tools live in the gui bundle. Not available
# to root/sudo sessions, by design.
{ inputs, ... }:
{
  homeManager.base =
    { lib, pkgs, ... }:
    let
      # trashy 2.0.0's generated zsh completion has two rest-argument specs
      # (`trash <paths>` and `trash <subcommand> ...`), which zsh rejects on
      # every Tab ("doubled rest argument definition"). Patched: the first
      # argument offers subcommands and files, and when it isn't a subcommand
      # the rest complete as files. The subcommand is then $line[1], not [2].
      # --replace-fail makes a changed upstream file fail the build.
      trashy = pkgs.symlinkJoin {
        inherit (pkgs.trashy) name meta;
        paths = [ pkgs.trashy ];
        postBuild = ''
          f=$out/share/zsh/site-functions/_trash
          rm "$f"
          cp ${pkgs.trashy}/share/zsh/site-functions/_trash "$f"
          substituteInPlace "$f" \
            --replace-fail ${lib.escapeShellArg "'*::paths -- The paths to put into the trash:_files' \\\n\":: :_trash_commands\" \\"} ${lib.escapeShellArg "\":: :_trash_first_arg\" \\"} \
            --replace-fail '$line[2]' '$line[1]' \
            --replace-fail ${lib.escapeShellArg "        esac\n    ;;\nesac\n}"} ${lib.escapeShellArg "            (*)\n_files && ret=0\n;;\n        esac\n    ;;\nesac\n}"} \
            --replace-fail ${lib.escapeShellArg "(( $+functions[_trash_commands] )) ||"} ${lib.escapeShellArg "_trash_first_arg() {\n    _alternative 'commands:command:_trash_commands' 'files:file:_files'\n}\n\n(( $+functions[_trash_commands] )) ||"}
        '';
      };
    in
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
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ trashy ];
    };
}
