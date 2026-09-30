# Face unlock for hyprlock via the IR camera. Opt-in: a host imports
# nixos.howdy. Paused on the thinkpad (face match kept returning "no match").
{
  nixos.howdy =
    { lib, ... }:
    {
      services.howdy = {
        enable = true;
        # Face alone unlocks, password still works as the fallback.
        control = "sufficient";
        settings.video = {
          device_path = "/dev/v4l/by-id/usb-SunplusIT_Inc_Integrated_IR_Camera-video-index0";
          # This camera's YUYV mode is unusable garbage; only MJPG (640x480) gives a
          # real IR image, and OpenCV would otherwise pick YUYV.
          force_mjpeg = true;
          # Lower = stricter (howdy recommends 3.5-5.0). Default 3.5 rejected the
          # enrolled face; `howdy test` prints the measured value on a match.
          certainty = 5.0;
        };
      };

      # `services.howdy.enable` turns the PAM hook on for every PAM service by
      # default (greetd, login, sudo, polkit...). Only hyprlock should use it.
      security.pam.howdy.enable = lib.mkForce false;
      security.pam.services.hyprlock.howdy.enable = true;

      # No services.linux-enable-ir-emitter: this camera's IR emitter already
      # flashes on its own (`linux-enable-ir-emitter configure` reports "already
      # working"), so the service had nothing to configure and did nothing.
    };
}
