{
  config,
  lib,
  pkgs,
  host,
  ...
}:
let
  cfg = host.gpu.nvidia;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.driver};
      modesetting.enable = true;
      open = cfg.open;
      powerManagement.enable = true;
      prime = lib.mkIf cfg.prime.enable {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        inherit (cfg.prime) intelBusId nvidiaBusId;
      };
    };

    # CUDA toolkit and the nixos-cuda binary cache (independent of the
    # optional global cudaSupport set in flake.nix nixpkgsConfig).
    environment.systemPackages = lib.optional cfg.cuda pkgs.cudaPackages.cudatoolkit;
    nix.settings = lib.mkIf cfg.cuda {
      substituters = [ "https://cache.nixos-cuda.org" ];
      trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
    };
  };
}
