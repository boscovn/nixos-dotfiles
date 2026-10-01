# Home-manager-only host on a non-NixOS Linux distribution (also Ubuntu & co.
# on WSL). Created from templates/home (see modules/flake/new-host.nix); the
# host is named after this directory. Switch with `hms`.
let
  name = baseNameOf ./.;
in
{
  hosts.${name} = {
    system = "@system@";
    nixos = false;
  };

  homeManager.${name} = {
    # The release this host was set up with; never change it.
    home.stateVersion = "@stateVersion@";
    # Desktop entries, XDG_DATA_DIRS and locale on a non-NixOS distribution.
    targets.genericLinux.enable = true;
  };
}
