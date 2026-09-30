{ config, ... }:
{
  homeManager.base =
    { lib, pkgs, ... }:
    {
      options.dotfiles.gui = lib.mkEnableOption "the Linux desktop session (set by the gui bundle)";

      config.home = {
        username = config.my.user;
        homeDirectory =
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${config.my.user}" else "/home/${config.my.user}";
      };
    };
}
