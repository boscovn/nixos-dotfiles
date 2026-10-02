{
  homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
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
        shellAliases = rebuildAliases // {
          ls = "${pkgs.eza}/bin/eza";
        };
      };
      programs.bash = {
        enable = true;
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
