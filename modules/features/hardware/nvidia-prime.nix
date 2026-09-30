# PRIME render offload for hybrid Intel + Nvidia laptops (`nvidia-offload
# <cmd>`). The host must set hardware.nvidia.prime.{intelBusId,nvidiaBusId}.
{
  nixos.nvidia-prime.hardware.nvidia.prime.offload = {
    enable = true;
    enableOffloadCmd = true;
  };
}
