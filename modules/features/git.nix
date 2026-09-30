{ config, ... }:
{
  homeManager.base = {
    programs.git = {
      enable = true;
      settings.user = {
        name = config.my.fullName;
        inherit (config.my) email;
      };
    };
    programs.gh.enable = true;
  };
}
