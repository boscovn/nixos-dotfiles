{
  nixos.gui =
    { pkgs, ... }:
    {
      fonts.packages = [
        pkgs.nerd-fonts.fira-code
        pkgs.font-awesome
      ];
    };
}
