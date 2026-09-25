{
  pkgs,
  host,
  ...
}:
{
  imports = [
    ./desktop
    ./features.nix
    ./hardware/nvidia.nix
    ./hardware/intel-graphics.nix
    ../stylix.nix
  ];

  services.fwupd.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  # Required for the LUKS passphrase to get cached into the kernel keyring
  # during boot, which is what lets pam_gnome_keyring (greetd's
  # KeyringMode=shared) auto-unlock the login keyring under autologin
  # without it, gnome-keyring-daemon starts but the keyring stays locked.
  boot.plymouth.enable = true;

  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ host.user ];
  };

  environment.sessionVariables.EDITOR = "nvim";

  fonts.packages = [
    pkgs.nerd-fonts.fira-code
    pkgs.font-awesome
  ];

  networking.networkmanager.enable = true;

  time.timeZone = host.timeZone;
  i18n.defaultLocale = host.locale;
  i18n.extraLocaleSettings = builtins.listToAttrs (
    map
      (name: {
        inherit name;
        value = host.regionalLocale;
      })
      [
        "LC_ADDRESS"
        "LC_IDENTIFICATION"
        "LC_MEASUREMENT"
        "LC_MONETARY"
        "LC_NAME"
        "LC_NUMERIC"
        "LC_PAPER"
        "LC_TELEPHONE"
        "LC_TIME"
      ]
  );
  services.xserver.xkb = {
    layout = host.keyMap;
    variant = "";
  };
  console.keyMap = host.keyMap;

  programs.zsh.enable = true;
  users.users.${host.user} = {
    isNormalUser = true;
    description = "Bosco";
    extraGroups = [
      "adbusers"
      "networkmanager"
      "video"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  security.pki.certificates = [
    (builtins.readFile ../../certs/pimps.crt)
    (builtins.readFile ../../certs/pim.pa.crt)
  ];

  hardware.graphics.enable = true;

  system.stateVersion = "24.05";
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
