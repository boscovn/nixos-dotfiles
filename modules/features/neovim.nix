# Neovim lives in its own flake (~/nvim, github:boscovn/nvim; nixvim config).
# home-manager only installs an `nvim` launcher (+ `vim`), so nixvim is no
# longer evaluated by every `hms`/`reb` (~20s, half the home evaluation):
#
# - uses ~/nvim when it exists (this machine: edits apply on the next launch,
#   uncommitted ones too, no --override-input), else github:boscovn/nvim;
# - builds only when ~/nvim's files changed since the last build (or there is
#   none yet; NVIM_REBUILD=1 forces one, e.g. to update from GitHub), keeping
#   the result as a GC root in ~/.cache/nvim-flake;
# - a failed rebuild falls back to the previous build.
#
# Its colours are its own (tokyonight); stylix doesn't theme it.
{
  homeManager.base =
    { lib, pkgs, ... }:
    let
      launcher = pkgs.writeShellApplication {
        name = "nvim";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
        ];
        text = ''
          local_flake=''${NVIM_FLAKE_DIR:-$HOME/nvim}
          cache=''${XDG_CACHE_HOME:-$HOME/.cache}/nvim-flake
          result=$cache/result

          if [ -f "$local_flake/flake.nix" ]; then
            ref="path:$local_flake"
            key=$(cd "$local_flake" &&
              find . -path ./.git -prune -o -type f ! -name 'result*' -print0 |
              sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)
          else
            ref="github:boscovn/nvim"
            key=$ref
          fi

          if [ -n "''${NVIM_REBUILD:-}" ] || [ ! -x "$result/bin/nvim" ] ||
            [ "$(cat "$cache/key" 2>/dev/null)" != "$key" ]; then
            mkdir -p "$cache"
            echo "nvim: building $ref ..." >&2
            if nix build "$ref" --out-link "$result"; then
              echo "$key" >"$cache/key"
            elif [ -x "$result/bin/nvim" ]; then
              echo "nvim: build failed, using the previous build" >&2
            else
              exit 1
            fi
          fi

          exec -a "$0" "$result/bin/nvim" "$@"
        '';
      };
    in
    {
      # With the launcher, so every host that has it (NixOS or not) uses it:
      # shells, and programs started by user services (e.g. an aerc opened
      # from a mail notification, whose composer runs $EDITOR).
      home.sessionVariables.EDITOR = "nvim";
      systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        EDITOR = "nvim";
      };

      home.packages = [
        (pkgs.symlinkJoin {
          name = "nvim-launcher";
          paths = [ launcher ];
          postBuild = "ln -s nvim $out/bin/vim";
        })
      ];
    };
}
