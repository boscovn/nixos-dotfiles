# CUDA toolkit and the nixos-cuda binary cache. This does not set nixpkgs'
# global cudaSupport (hosts.<name>.nixpkgsConfig.cudaSupport): that rebuilds
# every CUDA-capable package (firefox pulls a ~6 GiB CUDA onnxruntime); prefer
# explicit packages such as pkgs.ollama-cuda.
{
  nixos.cuda =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.cudaPackages.cudatoolkit ];
      nix.settings = {
        substituters = [ "https://cache.nixos-cuda.org" ];
        trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
      };
    };
}
