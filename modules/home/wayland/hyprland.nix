{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";
    # settings = {
    #   monitor = ",preferred,auto,auto";
    #
    #   env = [
    #     "XCURSOR_SIZE,24"
    #     "HYPRCURSOR_SIZE,24"
    #   ];
    #
    #   # "$terminal" = "ghostty";  # invalid Lua identifier ($), inline values in binds instead
    #   # "$fileManager" = "dolphin";
    #   # "$menu" = "fuzzel";
    #   # "$mainMod" = "SUPER";
    #
    #   general = {
    #     gaps_in = 5;
    #     gaps_out = 20;
    #     border_size = 2;
    #     # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
    #     # "col.inactive_border" = "rgba(595959aa)";
    #     resize_on_border = false;
    #     allow_tearing = false;
    #     layout = "dwindle";
    #   };
    #
    #   decoration = {
    #     rounding = 10;
    #     active_opacity = 1.0;
    #     inactive_opacity = 1.0;
    #     blur = {
    #       enabled = true;
    #       size = 3;
    #       passes = 1;
    #       vibrancy = 0.1696;
    #     };
    #   };
    #
    #   # animations = {
    #   #   enabled = true;
    #   #   bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
    #   #   animation = [
    #   #     "windows, 1, 7, myBezier"
    #   #     "windowsOut, 1, 7, default, popin 80%"
    #   #     "border, 1, 10, default"
    #   #     "borderangle, 1, 8, default"
    #   #     "fade, 1, 7, default"
    #   #     "workspaces, 1, 6, default"
    #   #   ];
    #   # };
    #
    #   dwindle = {
    #     # pseudotile = true;
    #     preserve_split = true;
    #   };
    #
    #   master = {
    #     new_status = "master";
    #   };
    #
    #   misc = {
    #     force_default_wallpaper = -1;
    #     # disable_hyprland_logo = false;
    #   };
    #
    #   xwayland = {
    #     force_zero_scaling = true;
    #   };
    #
    #   input = {
    #     kb_layout = "es,us";
    #     kb_options = "grp:alt_shift_toggle";
    #     follow_mouse = 1;
    #     sensitivity = 0;
    #     touchpad = {
    #       natural_scroll = false;
    #     };
    #   };
    #
    #   device = {
    #     name = "epic-mouse-v1";
    #     sensitivity = -0.5;
    #   };
    #
    # };
    extraConfig = ''
      hl.config({
        input = {
          kb_layout  = "es,us",
          kb_options = "grp:alt_shift_toggle",
          follow_mouse = 1,
          sensitivity  = 0,
          touchpad = { natural_scroll = false },
        },
      })

      local terminal    = "ghostty"
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

      for i = 1, 9 do
        hl.bind(mainMod .. " + " .. i,             hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. i,     hl.dsp.window.move({ workspace = i }))
      end

      hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
      hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

      hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
      hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, repeating = true })
    '';
  };
  services.hyprpaper.enable = true;
}
