# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS + Home Manager dotfiles for a ThinkPad (x86_64-linux). Everything is declarative. The structure follows a dendritic pattern: shared modules branch out from a common root, and host directories contain only machine-specific config.

## Key Commands

```bash
# Rebuild and switch (also aliased as `reb` in zsh)
sudo nixos-rebuild switch --flake ~/.dotfiles#thinkpad

# Format all Nix files
nix fmt

# Check formatting and flake validity
nix flake check
```

## Architecture

### Entry Point

**`flake.nix`** defines inputs and a `mkSystem` helper:
```nix
mkSystem { hostname = "thinkpad"; }
# Optional overrides:
mkSystem { hostname = "desktop"; system = "x86_64-linux"; user = "bosco"; }
```
Each host gets: `stylix` + `modules/nixos/common.nix` + `hosts/<hostname>` for the NixOS config, and `modules/home` as the Home Manager config (with `inputs`, `hostname`, and `user` passed as special args to both).

### Adding a New Host

1. Create `hosts/<hostname>/default.nix` — set `networking.hostName`, import `./hardware-configuration.nix` and any hardware profiles from `modules/nixos/hardware/`
2. Add the auto-generated `hosts/<hostname>/hardware-configuration.nix`
3. Register in `flake.nix`: `nixosConfigurations.<hostname> = mkSystem { hostname = "<hostname>"; };`

### Module Tree

```
modules/
├── nixos/
│   ├── common.nix          # Shared system config: boot, locale, user, audio, packages
│   ├── desktop/            # SDDM display manager + Hyprland (NixOS-level)
│   └── hardware/
│       └── nvidia.nix      # Intel+Nvidia hybrid GPU (offload mode)
└── home/
    ├── default.nix         # Shared Home Manager config for the user
    ├── wayland/            # Hyprland WM config, Waybar, hypridle, fuzzel, ghostty
    ├── nixvim/             # Neovim via nixvim (LSP, DAP, telescope, cmp, keymaps)
    ├── shell/              # Zsh, bash, starship, zoxide, atuin
    └── email/              # aerc, mbsync, msmtp, notmuch, gopass

hosts/
└── thinkpad/
    ├── default.nix         # hostname, nvidia.nix import, thinkpad-specific packages
    └── hardware-configuration.nix
```

### NixOS vs Home Manager Split

- `modules/nixos/` — system services, hardware, display manager, boot, kernel, system packages
- `modules/home/` — user programs, dotfiles, user services, user packages

When adding something: if it needs root or is a system service → `modules/nixos/` (or the host). If it's user-space config → `modules/home/`.

### Special Args

Both NixOS (`specialArgs`) and Home Manager (`extraSpecialArgs`) receive:
- `inputs` — flake inputs (needed by `modules/home/nixvim` for `inputs.nixvim.homeModules.nixvim`)
- `hostname` — used in the `reb` shell alias in `modules/home/shell`
- `user` — username string, used in `modules/nixos/common.nix` for `users.users.${user}` and in `modules/home/default.nix` for `home.username`
