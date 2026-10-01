# PRIME render offload for hybrid Intel + Nvidia laptops (`nvidia-offload
# <cmd>`). The GPU bus IDs default to the ones in the host's nixos-facter
# report; without a report the host sets hardware.nvidia.prime.{intelBusId,
# nvidiaBusId} itself.
{
  nixos.nvidia-prime =
    { config, lib, ... }:
    let
      cards = config.hardware.facter.report.hardware.graphics_card or [ ];
      # sysfs "0000:01:00.0" (hex) -> PRIME's "PCI:1:0:0" (decimal).
      busId =
        vendor:
        let
          card = lib.findFirst (c: c.vendor.hex or "" == vendor) null cards;
          parts = lib.splitString ":" (lib.replaceStrings [ "." ] [ ":" ] card.sysfs_bus_id);
        in
        lib.mkIf (card != null) (
          lib.mkDefault ("PCI:" + lib.concatMapStringsSep ":" (p: toString (lib.fromHexString p)) (lib.drop 1 parts))
        );
    in
    {
      hardware.nvidia.prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = busId "8086";
        nvidiaBusId = busId "10de";
      };
    };
}
