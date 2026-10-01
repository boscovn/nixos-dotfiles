# The thinkpad's existing disk (WDC SN720 512G; the 128G Toshiba is unused):
# GPT with a 512M ESP and a LUKS partition holding ext4 at /.
#
# Describes the disk as it was installed, without disko. NixOS only uses the
# fileSystems / boot.initrd.luks.devices this generates; nothing is
# partitioned unless disko's format script is run explicitly.
#
# The `device` overrides keep the mounts on the existing UUIDs. They only
# exist on this install: to reinstall with disko, remove them (disko then uses
# the partition labels it creates) or the format script will fail.
{
  disko.devices.disk.main = {
    type = "disk";
    # by-path (PCI slot), not by-id, which carries the serial number.
    device = "/dev/disk/by-path/pci-0000:3d:00.0-nvme-1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "EFI";
          type = "EF00";
          size = "512M";
          content = {
            type = "filesystem";
            format = "vfat";
            device = "/dev/disk/by-uuid/2D0C-4413";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        root = {
          label = "root";
          size = "100%";
          content = {
            type = "luks";
            name = "luks-7a727c1d-f7e6-4fc6-b09b-f13572941332";
            device = "/dev/disk/by-uuid/7a727c1d-f7e6-4fc6-b09b-f13572941332";
            content = {
              type = "filesystem";
              format = "ext4";
              device = "/dev/disk/by-uuid/f473bd00-3225-42a0-b45c-c2be6ccf1f24";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
