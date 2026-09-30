{
  nixos.gui = {
    nix.settings.trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    nix.settings.substituters = [ "https://hyprland.cachix.org" ];

    programs.hyprland.enable = true;
    programs.hyprland.withUWSM = true;
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

      config = {
        wayland.windowManager.hyprland = {
          enable = true;
          package = null;
          portalPackage = null;
          systemd.enable = false;
          configType = "lua";
          extraConfig = /* lua */ ''
            hl.config({
              input = {
                kb_layout  = "${config.dotfiles.kbLayouts}",
                kb_options = "grp:alt_shift_toggle",
                follow_mouse = 1,
                sensitivity  = 0,
                touchpad = { natural_scroll = false },
              },
             decoration = {rounding = 18, rounding_power = 2.5}, 
            })

            local terminal    = "ghostty +new-window"
            local fileManager = "dolphin"
            local menu        = "fuzzel"
            local mainMod     = "SUPER"

            hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd(terminal))
            hl.bind(mainMod .. " + N",              hl.dsp.exec_cmd("swaync-client -op"))
            hl.bind(mainMod .. " + Q",              hl.dsp.window.close())
            hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())
            hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd(fileManager))
            hl.bind(mainMod .. " + V",              hl.dsp.window.float({ action = "toggle" }))
            hl.bind(mainMod .. " + D",              hl.dsp.exec_cmd(menu))
            hl.bind(mainMod .. " + Escape",         hl.dsp.exec_cmd("hyprlock"))
            hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())
            -- hl.bind(mainMod .. " + M",           hl.dsp.layout("togglesplit"))
            hl.bind(mainMod .. " + h",              hl.dsp.focus({ direction = "left" }))
            hl.bind(mainMod .. " + l",              hl.dsp.focus({ direction = "right" }))
            hl.bind(mainMod .. " + j",              hl.dsp.focus({ direction = "down" }))
            hl.bind(mainMod .. " + k",              hl.dsp.focus({ direction = "up" }))
            hl.bind(mainMod .. " + S",              hl.dsp.workspace.toggle_special("magic"))
            hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.window.move({ workspace = "special:magic" }))
            hl.bind(mainMod .. " + mouse_down",     hl.dsp.focus({ workspace = "e+1" }))
            hl.bind(mainMod .. " + mouse_up",       hl.dsp.focus({ workspace = "e-1" }))
            hl.bind(mainMod .. " + 0",              hl.dsp.focus({ workspace = 10 }))
            hl.bind(mainMod .. " + SHIFT + 0",      hl.dsp.window.move({ workspace = 10 }))
            hl.bind(mainMod .. " + SHIFT + P",      hl.dsp.exec_cmd("grim -g $(slurp)"))

            for i = 1, 9 do
              hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
              hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
            end

            hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
            hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

            -- Routed through ashell's IPC (instead of wpctl/brightnessctl directly)
            -- so its OSD shows on each press; ashell.nix's [settings] max_volume=150
            -- keeps the old wpctl -l 1.5 boost-past-100% headroom.
            hl.bind("XF86AudioRaiseVolume",     hl.dsp.exec_cmd("ashell msg volume-up"),         { locked = true, repeating = true })
            hl.bind("XF86AudioLowerVolume",     hl.dsp.exec_cmd("ashell msg volume-down"),       { locked = true, repeating = true })
            hl.bind("XF86AudioMute",            hl.dsp.exec_cmd("ashell msg volume-toggle-mute"),{ locked = true, repeating = true })
            hl.bind("XF86MonBrightnessUp",      hl.dsp.exec_cmd("ashell msg brightness-up"),     { locked = true, repeating = true })
            hl.bind("XF86MonBrightnessDown",    hl.dsp.exec_cmd("ashell msg brightness-down"),   { locked = true, repeating = true })
          '';
        };
        services.hyprpaper.enable = true;
      };
    };
}
