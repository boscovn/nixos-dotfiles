{ inputs, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
    in
    {
      formatter = treefmtEval.config.build.wrapper;
      checks.formatting = treefmtEval.config.build.check self;
    };
}
