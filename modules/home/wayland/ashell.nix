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
        "KeyboardLayout"
        "SystemInfo"
        [
          "Tempo"
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
        "Spanish" = "🇪🇸";
        "English (US)" = "🇺🇸";
      };
    };
  };
}
