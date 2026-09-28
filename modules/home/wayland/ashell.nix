{ pkgs, ... }:
{

  programs.ashell.enable = true;
  programs.ashell.systemd.enable = true;
  programs.ashell.settings = {
    osd = {
      enabled = true;
      show_volume_percentage = true;
      show_brightness_percentage = true;
    };
    settings = {
      # Preserves the old `wpctl set-volume -l 1.5` headroom (boost past 100%).
      max_volume = 150;
    };
    appearence.menu = {
      opacity = 0.8;
    };

    modules = {
      center = [
        "WindowTitle"
      ];
      left = [
        "KeyboardLayout"
        "Workspaces"
      ];
      right = [
        "MediaPlayer"
        "SystemInfo"
        [
          "Tempo"
          "Privacy"
          "Tray"
          "Settings"
        ]
      ];
    };
    workspaces = {
      visibility_mode = "MonitorSpecific";
    };
    window_title = {
      mode = "Title";
      truncate_title_after_length = 75;
    };
    keyboard_layout = {
      labels = {
        "Spanish" = "🇪🇸";
        "English (US)" = "🇺🇸";
      };
    };
  };
}
