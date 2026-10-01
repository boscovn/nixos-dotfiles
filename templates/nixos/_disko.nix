# GPT: 1G ESP at /boot, the rest LUKS with ext4 at /.
# NixOS only uses the fileSystems / LUKS entries this generates; the disk is
# partitioned only when disko's format script runs (disko-install,
# nixos-anywhere), which ERASES it.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "@disk@";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
