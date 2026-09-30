{ config, ... }:
{
  nixos.docker =
    { lib, ... }:
    {
      virtualisation.docker.enable = true;
      # Started on demand by the socket; a host can set this to true.
      virtualisation.docker.enableOnBoot = lib.mkDefault false;
      users.users.${config.my.user}.extraGroups = [ "docker" ];
    };
}
