{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./modules/wayland
    ./modules/shell
  ];
  home.username = "bosco";
  home.homeDirectory = "/home/bosco";
  home.stateVersion = "24.05";
  programs.mpv = {
    enable = true;
    config = {
      save-position-on-quit = true;

    };
  };
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  programs.git = {
    enable = true;
    userName = "Bosco Vallejo-Nágera";
    userEmail = "bosco@vallejonagera.xyz";
  };
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    lsp.servers = {
      gopls.enable = true;
    };
    plugins = {
      oil.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
      treesitter.enable = true;
      cmp = {
        autoEnableSources = true;
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };

    };
  };
}
