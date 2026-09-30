# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NixOS + Home Manager dotfiles, currently one host (a ThinkPad, x86_64-linux). Everything is declarative and parametrized per host: shared modules branch out from a common root, host directories hold hardware config and a small `host.nix` of data, and modules switch themselves on/off from that data.

## Key Commands

```bash
# Rebuild and switch (also aliased as `reb` in zsh); `hms` for home-manager only
sudo nixos-rebuild switch --flake ~/.dotfiles#thinkpad

# Format all Nix files
nix fmt

# Check formatting and flake validity
nix flake check
```

## Architecture

### Entry Point

**`flake.nix`** defines inputs and two helpers, both taking just a hostname:
```nix
mkSystem { hostname = "thinkpad"; }   # NixOS + embedded home-manager  (reb)
mkHome   { hostname = "thinkpad"; }   # standalone home-manager        (hms)
```
Everything host-specific comes from **host data** (below), not from arguments. `mkSystem` builds: `stylix` + `modules/nixos/common.nix` + `hosts/<hostname>` for the NixOS config, and `modules/home` as the Home Manager config. `nixpkgs.config` is derived once from host data (`nixpkgsConfig` in `flake.nix`) and shared by both, so `reb` and `hms` build the same package set.

### Host Data (parametrization)

Each host is plain data, merged as `hosts/defaults.nix` ← `hosts/<name>/host.nix` (recursive), and passed to **every** NixOS and home-manager module as the `host` argument (so `reb` and standalone `hms` always agree). Fields: `system`, `user`, `os` (`"linux"`/`"darwin"`), `wsl`, `profiles` (below), `timeZone`, `locale`, `regionalLocale`, `keyMap`, `kbLayouts`, `gpu.{intel,nvidia}` (nvidia: `enable`, `cuda`, `globalCudaSupport`, `driver`, `open`, `prime.*`), and `features.{laptop,bluetooth,docker,dockerOnBoot,gaming,kdeconnect,ssh,nixbuild}`. See `hosts/defaults.nix` for the full list and meanings.

Modules gate themselves on `host` (`lib.mkIf host.gpu.nvidia.enable`, ...), so a machine without an Nvidia GPU never sees the nvidia driver or the CUDA toolkit/cache. Video decoding deliberately stays on the iGPU (`hwdec = "vaapi"` in `profiles/desktop.nix`): the MX150 exposes no usable NVDEC (ffmpeg `-hwaccel cuda` reports "Hardware is lacking required capabilities" for H.264, HEVC and VP9), and decoding on the iGPU avoids waking the dGPU. `globalCudaSupport` is off deliberately: it rebuilds CUDA-capable packages system-wide (e.g. firefox pulls a ~6 GiB CUDA onnxruntime) — use explicit packages like `pkgs.ollama-cuda` instead.

### Home-manager profiles

`modules/home/default.nix` is the single home-manager entry point for both `reb` (embedded) and `hms` (standalone). It always imports `profiles/core.nix`, then one file per name in `host.profiles` (`modules/home/profiles/<name>.nix`):

- **core** (always): terminal-only and portable - shell, git, gh, gpg (+ `gpg-agent` on Linux, pinentry chosen per platform), nixvim, yazi, CLI tools (`tools.nix`). Nothing here may assume a Linux desktop.
- **email**: terminal mail stack (aerc, mbsync, msmtp, notmuch, hydroxide). Thunderbird is added only when `desktop` is also present.
- **desktop**: Linux GUI session - Hyprland (`wayland/`), browsers, media (`media.nix`), GUI apps, GUI fonts, `xdg.mimeApps`, gnome-keyring plumbing.

A WSL, darwin or server host just omits `desktop`. `host.os` handles the remaining small platform differences (`home.homeDirectory`, `gpg-agent`, the `reb` alias, pinentry); stylix only auto-enables its GUI targets with `desktop`. There are deliberately no darwin/WSL hosts yet; to prove a change stays portable, temporarily add a throwaway `hosts/<x>/host.nix` (`{ os = "darwin"; system = "aarch64-darwin"; }`) plus a `homeConfigurations` entry and `nix eval ...activationPackage.drvPath` it (darwin can only be evaluated on Linux, and that is what catches Linux-only packages/options).

### Adding a New Host

1. Create `hosts/<hostname>/default.nix` — set `networking.hostName`, import `./hardware-configuration.nix` (and opt-in profiles like `modules/nixos/hardware/howdy.nix`)
2. Create `hosts/<hostname>/host.nix` — only what differs from `hosts/defaults.nix` (may be `{ }`); set `profiles` (e.g. `[ "email" "desktop" ]`)
3. Add the auto-generated `hosts/<hostname>/hardware-configuration.nix`
4. Register in `flake.nix`: `nixosConfigurations.<hostname> = mkSystem { hostname = "<hostname>"; };` and `homeConfigurations."<user>@<hostname>" = mkHome { hostname = "<hostname>"; };`

### Module Tree

```
hosts/
├── defaults.nix            # baseline host data every host inherits
└── thinkpad/
    ├── default.nix         # hostname, hardware-configuration import, opt-in profiles
    ├── host.nix            # thinkpad host data (gpu, features)
    └── hardware-configuration.nix

modules/
├── stylix.nix              # shared stylix options (NixOS + standalone home-manager)
├── nixos/
│   ├── common.nix          # Shared system config: boot, locale/tz/keymap (from host), user, audio
│   ├── features.nix        # host.features.*: laptop, bluetooth, docker, gaming, kdeconnect, ssh, nixbuild
│   ├── desktop/            # greetd (autologin) + Hyprland/UWSM (NixOS-level)
│   └── hardware/
│       ├── nvidia.nix          # gated on host.gpu.nvidia (driver, PRIME offload, CUDA toolkit/cache)
│       ├── intel-graphics.nix  # gated on host.gpu.intel (VA-API/VDPAU)
│       └── howdy.nix           # opt-in profile, imported per host (currently paused)
└── home/
    ├── default.nix         # Entry point: always core, plus one profiles/<name>.nix per host.profiles
    ├── profiles/           # core (portable terminal), email, desktop (Linux GUI session)
    ├── tools.nix           # portable CLI tools (core): programs.<x>.enable where HM has a module, else home.packages
    ├── wayland/            # Hyprland WM config, hypridle, hyprlock, ashell, fuzzel, ghostty
    ├── nixvim/             # Neovim via nixvim (LSP, DAP, telescope, blink-cmp, keymaps)
    ├── shell/              # Zsh, bash, starship, zoxide, atuin
    └── email/              # aerc, mbsync, msmtp, notmuch, gopass
```

### NixOS vs Home Manager Split

- `modules/nixos/` — system services, hardware, display manager, boot, kernel; no shared `environment.systemPackages` (only hardware-gated extras like the CUDA toolkit)
- `modules/home/` — user programs, dotfiles, user services, **all user-facing packages**

When adding something: if it needs root or is a system service → `modules/nixos/`. If it's user-space config or a CLI tool → `modules/home/` (prefer `programs.<name>.enable` when home-manager has the module, otherwise `home.packages` in `tools.nix`; GUI or Linux-only things belong in `profiles/desktop.nix`, never in core). Note packages in home-manager are not on root's PATH (`sudo` sessions).

### Special Args

Both NixOS (`specialArgs`) and Home Manager (`extraSpecialArgs`) receive:
- `host` — the merged host data described above (prefer this for anything host-specific)
- `inputs` — flake inputs (needed by `modules/home/nixvim` for `inputs.nixvim.homeModules.nixvim`)
- `hostname` — used in the `reb`/`hms` shell aliases in `modules/home/shell`
- `user` — username string (same as `host.user`)
