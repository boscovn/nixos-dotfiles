{
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
  };

  features = {
    laptop = true;
    bluetooth = true;
    docker = true;
    gaming = true;
    kdeconnect = true;
    ssh = true;
  };
}
