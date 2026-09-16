{ pkgs, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms(\"on\")'";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "${pkgs.hyprlock}/bin/hyprlock";
        }
        {
          timeout = 1200;
          # This Hyprland build's `hyprctl dispatch <name> <args>` now routes
          # through a Lua evaluator (`hl.dispatch(<name> <args>)`), which
          # rejects the traditional space-separated "dpms off" form with a
          # parse error - confirmed via `hyprctl dispatch dpms off` erroring
          # on this machine's Hyprland 0.56.2. `hl.dsp.dpms(...)` is the
          # dispatcher called as a Lua function instead; verified it flips
          # `hyprctl monitors`' dpmsStatus correctly.
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms(\"off\")'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms(\"on\")'";
        }
      ];
    };
  };
}
