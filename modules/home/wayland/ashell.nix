{ pkgs, ... }:
{

  programs.ashell.enable = true;
  programs.ashell.systemd.enable = true;
  programs.ashell.settings = {
    modules = {
      center = [
        "Window Title"
      ];
      left = [
        "Workspaces"
      ];
      right = [
        "Keyboard Layout"
        "Battery"
        "SystemInfo"
        [
          "Clock"
          "Privacy"
          "Settings"
        ]
      ];
    };
    workspaces = {
      visibility_mode = "MonitorSpecific";
    };
    window_title = {
      mode = "Title";
    };
    keyboard_layout = {
      labels = {
        "Spanish" = "ES";
        "English (US)" = "US";
      };
    };
  };
}
