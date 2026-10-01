{
  nixos.gui = {
    nix.settings.trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    nix.settings.substituters = [ "https://hyprland.cachix.org" ];

    programs.hyprland.enable = true;
    programs.hyprland.withUWSM = true;
    # Becomes /etc/xdg/xdg-desktop-portal/hyprland-portals.conf, which replaces
    # the one Hyprland ships, so the full routing lives here.
    xdg.portal.config.hyprland = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
    };
    security.pam.services.hyprlock.enableGnomeKeyring = true;
  };

  homeManager.gui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.dotfiles.kbLayouts = lib.mkOption {
        type = lib.types.str;
        default = "es,us";
        description = "Hyprland keyboard layouts (first one is active; alt+shift toggles).";
      };

      options.dotfiles.terminal = lib.mkOption {
        type = lib.types.str;
        example = lib.literalExpression ''"''${lib.getExe config.programs.ghostty.package} +new-window"'';
        description = "Command that opens the preferred terminal (SUPER + Return); set by each host.";
      };

      config = {
        wayland.windowManager.hyprland =
          let
            # lib.getExe pkg is "${pkg}/bin/<meta.mainProgram>"; getExe' names the binary.
            # Programs home-manager manages use its package option, so overrides there apply.
            inherit (lib) getExe getExe';
            terminal = config.dotfiles.terminal;
            fileManager = getExe pkgs.kdePackages.dolphin;
            menu = getExe config.programs.fuzzel.package;
            lock = getExe config.programs.hyprlock.package;
            notifications = getExe' config.services.swaync.package "swaync-client";
            screenshot = ''${getExe pkgs.grim} -g "$(${getExe pkgs.slurp})"'';
            mainMod = "SUPER";

            # Dispatchers are Lua calls (hl.dsp.*), so they go in raw;
            # `dsp "exec_cmd" "kitty"` renders hl.dsp.exec_cmd("kitty").
            toLua = lib.generators.toLua { };
            dsp = name: arg: lib.generators.mkLuaInline "hl.dsp.${name}(${toLua arg})";
            dsp' = name: lib.generators.mkLuaInline "hl.dsp.${name}()";
            exec = dsp "exec_cmd";
            # hl.bind(keys, dispatcher[, opts])
            bind = keys: dispatcher: {
              _args = [
                keys
                dispatcher
              ];
            };
            bind' = keys: dispatcher: opts: {
              _args = [
                keys
                dispatcher
                opts
              ];
            };
            mod = keys: "${mainMod} + ${keys}";

            # With ashell, routed through its IPC so its OSD shows on each press
            # (ashell.nix's max_volume=150 keeps the boost past 100%); without it,
            # wpctl/brightnessctl directly, with the same -l 1.5 headroom.
            ashell = getExe config.programs.ashell.package;
            wpctl = getExe' pkgs.wireplumber "wpctl";
            brightnessctl = getExe pkgs.brightnessctl;
            mediaKey =
              key: ashellMsg: fallback:
              bind' key (exec (if config.programs.ashell.enable then "${ashell} msg ${ashellMsg}" else fallback))
                {
                  locked = true;
                  repeating = true;
                };
          in
          {
            enable = true;
            package = null;
            portalPackage = null;
            systemd.enable = false;
            configType = "lua";

            settings.config = {
              input = {
                kb_layout = config.dotfiles.kbLayouts;
                kb_options = "grp:alt_shift_toggle";
                follow_mouse = 1;
                sensitivity = 0;
                touchpad.natural_scroll = false;
              };
              decoration = {
                rounding = 18;
                rounding_power = 2.5;
              };
            };

            settings.bind = [
              (bind (mod "Return") (exec terminal))
              (bind (mod "N") (exec "${notifications} -op"))
              (bind (mod "Q") (dsp' "window.close"))
              (bind (mod "F") (dsp' "window.fullscreen"))
              (bind (mod "E") (exec fileManager))
              (bind (mod "V") (dsp "window.float" { action = "toggle"; }))
              (bind (mod "D") (exec menu))
              (bind (mod "Escape") (exec lock))
              (bind (mod "P") (dsp' "window.pseudo"))
              # (bind (mod "M") (dsp "layout" "togglesplit"))
              (bind (mod "h") (dsp "focus" { direction = "left"; }))
              (bind (mod "l") (dsp "focus" { direction = "right"; }))
              (bind (mod "j") (dsp "focus" { direction = "down"; }))
              (bind (mod "k") (dsp "focus" { direction = "up"; }))
              (bind (mod "S") (dsp "workspace.toggle_special" "magic"))
              (bind (mod "SHIFT + S") (dsp "window.move" { workspace = "special:magic"; }))
              (bind (mod "mouse_down") (dsp "focus" { workspace = "e+1"; }))
              (bind (mod "mouse_up") (dsp "focus" { workspace = "e-1"; }))
              (bind (mod "SHIFT + P") (exec screenshot))
            ]
            # SUPER + 1..9,0 focuses workspace 1..10; with SHIFT, moves the window there.
            ++ lib.concatMap (
              ws:
              let
                key = toString (lib.mod ws 10);
              in
              [
                (bind (mod key) (dsp "focus" { workspace = ws; }))
                (bind (mod "SHIFT + ${key}") (dsp "window.move" { workspace = ws; }))
              ]
            ) (lib.range 1 10)
            ++ [
              (bind' (mod "mouse:272") (dsp' "window.drag") { mouse = true; })
              (bind' (mod "mouse:273") (dsp' "window.resize") { mouse = true; })
              (mediaKey "XF86AudioRaiseVolume" "volume-up" "${wpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")
              (mediaKey "XF86AudioLowerVolume" "volume-down" "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-")
              (mediaKey "XF86AudioMute" "volume-toggle-mute" "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle")
              (mediaKey "XF86MonBrightnessUp" "brightness-up" "${brightnessctl} set 5%+")
              (mediaKey "XF86MonBrightnessDown" "brightness-down" "${brightnessctl} set 5%-")
            ];
          };
        services.hyprpaper.enable = true;
      };
    };
}
