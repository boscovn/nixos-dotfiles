{
  homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # `nix run ~/.dotfiles#nvim` re-evaluates nixvim's whole plugin option tree
      # on every invocation (~25s+ on this machine), even when nothing changed.
      # Hash the inputs that actually affect the built package and skip straight
      # to the cached binary when they haven't changed since the last build.
      nnvimFn = ''
        nnvim() {
          local dotfiles="$HOME/.dotfiles"
          local cache="''${XDG_CACHE_HOME:-$HOME/.cache}/nnvim"
          mkdir -p "$cache"
          local hash
          hash=$(cat \
            "$dotfiles/flake.nix" \
            "$dotfiles/flake.lock" \
            "$dotfiles/modules/features/nixvim/_shared/config.nix" \
            "$dotfiles/modules/features/nixvim/_shared/keymaps.nix" \
            2>/dev/null | '${pkgs.coreutils}/bin/sha256sum' | '${pkgs.coreutils}/bin/cut' -d' ' -f1)
          if [ -x "$cache/bin/nvim" ] && [ "$(cat "$cache/hash" 2>/dev/null)" = "$hash" ]; then
            exec "$cache/bin/nvim" "$@"
          fi
          echo "nnvim: nixvim config changed, rebuilding..." >&2
          local out
          out=$(nix build "$dotfiles#nvim" --no-link --print-out-paths) || return 1
          echo "$hash" > "$cache/hash"
          ln -sfn "$out/bin" "$cache/bin"
          exec "$out/bin/nvim" "$@"
        }
      '';

      # Through nh (base/nix.nix), which picks the `<hostname>` /
      # `<user>@<hostname>` configuration itself. The flake is passed rather
      # than left to NH_FLAKE: home-manager's session variables load once per
      # login, so a newly added one is missing from terminals until re-login.
      # `reb` only on NixOS hosts; standalone home-manager (`hms`) works
      # everywhere.
      rebuildAliases =
        lib.optionalAttrs config.dotfiles.nixos {
          reb = "nh os switch ${config.programs.nh.flake}";
        }
        // {
          hms = "nh home switch ${config.programs.nh.flake}";
        };
    in
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        history.size = 10000;
        initContent = nnvimFn;
        shellAliases = rebuildAliases // {
          ls = "${pkgs.eza}/bin/eza";
        };
      };
      programs.bash = {
        enable = true;
        initExtra = nnvimFn;
        shellAliases = rebuildAliases;
      };
      programs.starship.enable = true;
      programs.zoxide.enable = true;
      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };
    };
}
