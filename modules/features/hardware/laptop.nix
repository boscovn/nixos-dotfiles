{
  nixos.laptop = {
    services.upower.enable = true;
    services.tlp = {
      enable = true;
      settings.USB_AUTOSUSPEND = 1;
    };
    # Keep running with the lid closed; Hyprland handles it (homeManager.laptop).
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # Lid close: disable the panel when another monitor is connected, else lock
  # and blank it; lid open restores it. Lua because it needs runtime logic.
  homeManager.laptop.wayland.windowManager.hyprland.extraLuaFiles.laptop-lid = ./laptop-lid.lua;
}
