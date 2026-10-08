# Services for the home server (the rock-5t, a home-manager-only host on its
# vendor distribution): user services, so systemd --user units, (re)started on
# `hms`. Lingering must be on for them to run without a login session:
# `sudo loginctl enable-linger radxa`.
#
# Each service gets its own file in this directory, all adding to
# homeManager.homeServer.
{
  homeManager.homeServer = { };
}
