{
  nixos.base = {
    networking.networkmanager.enable = true;
    security.pki.certificates = [
      (builtins.readFile ../../../certs/pimps.crt)
      (builtins.readFile ../../../certs/pim.pa.crt)
    ];
  };
}
