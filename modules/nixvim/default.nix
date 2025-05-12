{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    lsp.servers = {
      gopls.enable = true;
    };
    colorschemes.tokyonight.enable = true;
    plugins = {
      oil.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
      treesitter.enable = true;
      cmp = {
        enable = true;
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
