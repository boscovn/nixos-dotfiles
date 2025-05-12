{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.waybar.enable = true;
  programs.waybar.style = /* css */''
      * {
    	font-family = Fira Code;	
      }
  '';
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
        "eDP-1"
        "HDMI-A-1"
      ];
      modules-left = [
        "hyprland/workspaces"
        "hyprland/mode"
        "wlr/taskbar"
      ];
      modules-center = [
        "hyprland/window"
      ];
      modules-right = [
        "temperature"
        "pulseaudio"
        "battery"
      ];

      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
      };
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
}
