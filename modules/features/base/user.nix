{ config, ... }:
{
  nixos.base =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;
      users.users.${config.my.user} = {
        isNormalUser = true;
        description = "Bosco";
        extraGroups = [
          "adbusers"
          "networkmanager"
          "video"
          "wheel"
        ];
        shell = pkgs.zsh;
      };
    };
}
