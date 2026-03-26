{ pkgs, ... }:
{
  imports = [
    ./waybar.nix
    ./hypridle.nix
  ];
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
  ];
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
  };
  services.hyprpolkitagent.enable = true;
  services.swaync.enable = true;
  programs.fuzzel.enable = true;
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
  };
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
  };
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      allow_tearing = false;
      layout = "dwindle";
    };
    "$mod" = "SUPER";
    "$terminal" = "${pkgs.ghostty}";
    "$menu" = "${pkgs.fuzzel}";
    monitor = ",preffered,auto,auto";
    bind = [
      "$mod, F, fullscreen,"
      "$mod, Q, killactive,"
      "$mod, h, movefocus, l"
      "$mod, l, movefocus, r"
      "$mod, j, movefocus, d"
      "$mod, k, movefocus, u"
      "$mod, S, togglespecialworkspace, magic"
      "$mod SHIFT, S, movetoworkspace, special:magic"
    ]
    ++ (
      builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      )
    );
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
    bindl = [
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];
    binde = [
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
    ];
  };
}
