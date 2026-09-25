{ lib, ... }:
{
  services.howdy = {
    enable = true;
    # Face alone unlocks, password still works as the fallback.
    control = "sufficient";
    settings.video.device_path = "/dev/v4l/by-id/usb-SunplusIT_Inc_Integrated_IR_Camera-video-index0";
  };

  # `services.howdy.enable` turns the PAM hook on for every PAM service by
  # default (greetd, login, sudo, polkit...). Only hyprlock should use it.
  security.pam.howdy.enable = lib.mkForce false;
  security.pam.services.hyprlock.howdy.enable = true;

  # One-time setup after rebuilding: `sudo linux-enable-ir-emitter configure`.
  services.linux-enable-ir-emitter = {
    enable = true;
    device = "video0";
  };
}
