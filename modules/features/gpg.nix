{
  homeManager.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.gpg.enable = true;
      # HM's gpg-agent module is a systemd user service, so Linux only.
      services.gpg-agent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        # A graphical prompt only with a desktop session; curses on WSL/servers.
        pinentry.package = if config.dotfiles.gui then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
      };
    };
}
