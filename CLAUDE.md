# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS + Home Manager dotfiles repository for a single machine ("thinkpad", x86_64-linux). Everything is declarative — system config, user environment, desktop, editor, shell, and email.

## Key Commands

```bash
# Rebuild and switch the system (aliased as `reb` in zsh)
sudo nixos-rebuild switch --flake ~/.dotfiles#thinkpad

# Format all Nix files
nix fmt

# Check formatting and flake validity
nix flake check
```

## Architecture

### Entry Points
- **`flake.nix`** — Root. Defines inputs (nixpkgs unstable, home-manager, nixvim, stylix, treefmt-nix) and a single NixOS system output: `nixosConfigurations.thinkpad`.
- **`configuration.nix`** — NixOS system-level config. Imports `hardware-configuration.nix` and `modules/desktop`. Configures display manager (SDDM/Hyprland), Intel+Nvidia hybrid GPU, audio (PipeWire), Docker, boot, locale, and system packages.
- **`home.nix`** — Home Manager config for user `bosco`. Imports `modules/wayland`, `modules/nixvim`, `modules/shell`, `modules/email`. Manages user packages and program config.

### Modules
- **`modules/desktop/`** — NixOS-level desktop: SDDM display manager, Hyprland + UWSM, GNOME Keyring integration.
- **`modules/wayland/`** — Home Manager Wayland stack: Hyprland config (keybinds, gaps, layout), Waybar, hypridle, fuzzel launcher, ghostty terminal, screenshot tools (grim/slurp), swaync notifications.
- **`modules/nixvim/`** — Neovim via nixvim. LSP (gopls, nixd, clangd, yamlls, jsonls, zls), treesitter, telescope, oil, cmp, DAP. Keymaps in `keymaps.nix`. Mapleader = Space.
- **`modules/shell/`** — Zsh with autosuggestions, syntax highlighting, starship prompt, zoxide, atuin history. Bash also enabled.
- **`modules/email/`** — aerc mail client, mbsync + msmtp for IMAP/SMTP, notmuch for indexing, gopass for credentials. Account: bosco@vallejonagera.xyz (Hostinger).

### Theming
Stylix applies Catppuccin Mocha theme system-wide (terminal, applications, SDDM). Font: FiraCode Nerd Font. Terminal opacity: 0.8.

### Split Between `configuration.nix` and `home.nix`
- `configuration.nix` — system packages, hardware, services, display manager, NixOS options
- `home.nix` — user packages, dotfiles/program configs via Home Manager options

When adding something new: if it requires root/system-level access or is a system service, it goes in `configuration.nix` (or a `modules/desktop/` submodule). If it's user-space config or a user program, it goes in `home.nix` (or an appropriate `modules/` submodule).
