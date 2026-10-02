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
        # Per-project dev shells on `cd`: `use flake` / `use devenv` in .envrc,
        # then `direnv allow`. nix-direnv caches them in .direnv/ (globally
        # git-ignored, git.nix) as GC roots, re-evaluating only when the
        # flake/devenv files change.
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          silent = true;
        };
      };
      # `use devenv` without `eval "$(devenv direnvrc)"` in every .envrc:
      # devenv's direnv function, generated from the installed devenv into
      # direnv's library (loaded for every .envrc). It is adapted from
      # nix-direnv and reuses three of its helper names with different bodies;
      # in one library the later file's would replace the other's (breaking
      # `use devenv` or `use flake`), so devenv's are renamed. The build fails
      # if a devenv update changes them.
      xdg.configFile."direnv/lib/devenv.sh".source = pkgs.runCommand "devenv-direnvrc" { } ''
        HOME=$TMPDIR ${lib.getExe pkgs.devenv} direnvrc >raw
        sed -E 's/\b_nix_(direnv_preflight|export_or_unset|import_env)\b/_devenv_\1/g' raw >$out
        grep -q '^use_devenv' $out
        ! grep -qE '\b_nix_(direnv_preflight|export_or_unset|import_env)\b' $out
        grep -q '_devenv_direnv_preflight' $out
      '';

      home.packages =
        with pkgs;
        [
          claude-code
          delve
          devenv
          gopass
          gopls
          inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
          jq
          just
          nixd
          nixfmt
          opensc
          ouch
          pcsc-tools
          wget
        ]
        # trashy is Linux-only (freedesktop trash spec).
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ trashy ];
    };
}
