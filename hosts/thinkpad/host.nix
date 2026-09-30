{
  profiles = [
    "email"
    "desktop"
  ];

  gpu = {
    intel.enable = true;
    nvidia = {
      enable = true;
      cuda = true; # toolkit + cache; global cudaSupport intentionally off
      driver = "legacy_580";
      prime = {
        enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
    # Decode on the Intel iGPU: the MX150 exposes no usable NVDEC, and the
    # iGPU avoids waking the dGPU.
    video = {
      hwdec = "vaapi";
      api = "opengl";
    };
  };

  features = {
    laptop = true;
    bluetooth = true;
    docker = true;
    dockerOnBoot = false;
    gaming = true;
    kdeconnect = true;
    ssh = true;
    nixbuild = true;
  };
}
