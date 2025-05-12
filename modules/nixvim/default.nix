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
    lsp = {
      enable = true;
      servers = {
        gopls.enable = true;
      };
    };
    keymaps = [
      {
        action = "<cmd>Oil<CR>";
        key = "-";
      }
      {
        action = "<cmd>Telescope find_files<CR>";
        key = "<leader>sf";
        options.desc = "Search files with telescope";
      }
    ];
    colorschemes.tokyonight.enable = true;
    plugins = {
      oil.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
      treesitter.enable = true;
      which-key.enable = true;
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
