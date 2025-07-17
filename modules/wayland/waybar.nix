{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
        "eDP-1"
        "HDMI-A-2"
      ];
      modules-left = [
        "hyprland/workspaces"
        "wlr/taskbar"
      ];
      modules-center = [
        "hyprland/window"
      ];
      modules-right = [
        "hyprland/language"
        "temperature"
        "pulseaudio"
        "clock"
        "battery"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
      };
      temperature = {
        critical-threshold = 50;
        format = " {temperatureC}°C";
      };
      pulseaudio = {
        "format" = "{volume}% {icon}";
        "format-bluetooth" = "{volume}% {icon}";
        "format-muted" = "";
        "format-icons" = {
          "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
          "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
          "headphones" = "";
          "handsfree" = "";
          "headset" = "";
          "phone" = "";
          "phone-muted" = "";
          "portable" = "";
          "car" = "";
          "default" = [
            ""
            ""
          ];
        };
        "scroll-step" = 1;
        "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
    };
  };
}
