{
  homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.dotfiles.gui = lib.mkEnableOption "the Linux desktop session (set by the gui bundle)";

      config.home = {
        username = config.dotfiles.user;
        homeDirectory =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "/Users/${config.dotfiles.user}"
          else
            "/home/${config.dotfiles.user}";
      };
    };
}
