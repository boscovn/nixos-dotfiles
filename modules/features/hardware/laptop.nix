{
  nixos.laptop = {
    services.upower.enable = true;
    services.tlp = {
      enable = true;
      settings.USB_AUTOSUSPEND = 1;
    };
    # Keep running with the lid closed (docked / external display use).
    services.logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
    };
  };
}
