# Baseline every host inherits; hosts/<name>/host.nix overrides what differs
# (merged recursively in flake.nix's mkHost). Plain data only - it is read by
# both NixOS and home-manager modules through the `host` module argument, so
# `reb` (embedded home-manager) and standalone `hms` always agree.
{
  system = "x86_64-linux";
  user = "bosco";

  # Platform the home-manager config targets. "linux" or "darwin"; `wsl` marks a
  # Linux running under WSL (terminal-only, no desktop session).
  os = "linux";
  wsl = false;

  # Home-manager layers on top of the always-on core (modules/home/profiles/
  # core.nix: shell, git, gpg, nixvim, CLI tools). Each name is a file in
  # modules/home/profiles/:
  #   email   - terminal mail stack (aerc, mbsync, msmtp, notmuch)
  #   desktop - Linux GUI session: Hyprland, browsers, media, GUI apps
  # A WSL or darwin host simply omits "desktop".
  profiles = [ ];

  timeZone = "Europe/Madrid";
  locale = "en_GB.UTF-8";
  # Locale used for LC_* categories (dates, currency, paper size, ...).
  regionalLocale = "es_ES.UTF-8";
  # Console/X keymap, and the Hyprland layout list (first one is active).
  keyMap = "es";
  kbLayouts = "es,us";
}
