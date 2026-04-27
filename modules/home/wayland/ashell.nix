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
        "SystemInfo"
        [
          "Clock"
          "Privacy"
          "Settings"
        ]
      ];
    };
    workspaces = {
      visibilityMode = "MonitorSpecific";
    };
    windowTitle = {
      mode = "Title";
    };
  };
}
