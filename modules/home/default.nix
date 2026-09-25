# Single home-manager entry point for both `reb` (embedded) and `hms`
# (standalone). Always imports the core profile, then one file per name in
# host.profiles (see hosts/defaults.nix). `host` is a module argument rather
# than config, so importing on it cannot recurse.
{ host, user, ... }:
{
  imports = [
    ./profiles/core.nix
  ]
  ++ map (name: ./profiles/${name}.nix) host.profiles;

  home.username = user;
  home.homeDirectory = if host.os == "darwin" then "/Users/${user}" else "/home/${user}";
  home.stateVersion = "24.05";
}
