{ pkgs, user, ... }:
{
  imports = [
    ./desktop
  ];

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  stylix.opacity.terminal = 0.8;
  stylix.fonts.monospace = {
    package = pkgs.nerd-fonts.fira-code;
    name = "FiraCodeNerdFont";
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  virtualisation.docker.enable = true;
  programs.kdeconnect.enable = true;
  services.fwupd.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ user ];
  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables.EDITOR = "nvim";

  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    pkgs.font-awesome
  ];

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };
  console.keyMap = "es";

  programs.zsh.enable = true;
  users.users.${user} = {
    isNormalUser = true;
    description = "Bosco";
    extraGroups = [
      "adbusers"
      "docker"
      "networkmanager"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  services.gnome.gnome-keyring.enable = true;

  security.pki.certificates = [
    (builtins.readFile ../../certs/pimps.crt)
    (builtins.readFile ../../certs/pim.pa.crt)
  ];

  environment.systemPackages = with pkgs; [
    bat
    delve
    fd
    firefox
    foot
    ghostty
    go
    gopass
    gopass-jsonapi
    gopls
    hyprlock
    opensc
    pcsc-tools
    ripgrep
    trashy
    usbutils
    wget
  ];

  programs.steam.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.05";
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
