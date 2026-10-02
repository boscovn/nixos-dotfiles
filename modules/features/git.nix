{ config, ... }:
{
  homeManager.base = {
    programs.git = {
      enable = true;
      settings.user = {
        name = config.my.fullName;
        inherit (config.my) email;
      };
      # Global ignores: direnv's per-project cache (cli-tools.nix).
      ignores = [ ".direnv/" ];
    };
    programs.gh.enable = true;
  };
}
