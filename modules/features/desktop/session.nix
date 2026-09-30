{
  nixos.gui = {
    hardware.graphics.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    # Required for the LUKS passphrase to get cached into the kernel keyring
    # during boot, which is what lets pam_gnome_keyring (greetd's
    # KeyringMode=shared) auto-unlock the login keyring under autologin
    # without it, gnome-keyring-daemon starts but the keyring stays locked.
    boot.plymouth.enable = true;
  };
}
