# Values shared across features and configuration classes.
{ lib, ... }:
{
  options.my = {
    user = lib.mkOption { type = lib.types.str; };
    fullName = lib.mkOption { type = lib.types.str; };
    email = lib.mkOption { type = lib.types.str; };
  };
  config.my = {
    user = "bosco";
    fullName = "Bosco Vallejo-Nágera";
    email = "bosco@vallejonagera.xyz";
  };
}
