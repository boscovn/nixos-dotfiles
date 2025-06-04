{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./keymaps.nix
  ];
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    opts = {
      relativenumber = true;
    };
    lsp = {
      servers = {
        gopls.enable = true;
        nixd.enable = true;
      };
    };
    colorschemes.tokyonight.enable = true;
    plugins = {
      lsp.enable = true;
      oil.enable = true;
      otter.enable = true;
      snacks.enable = true;
      telescope.enable = true;
      web-devicons.enable = true;
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };
      which-key.enable = true;
      luasnip.enable = true;
      dap.enable = true;
      dap-ui.enable = true;
      dap-go.enable = true;
      cmp-omni.enable = true;
      cmp-dap.enable = true;
      cmp-nvim-lsp.enable = true;
      cmp-nvim-lsp-document-symbol.enable = true;
      cmp-nvim-lsp-signature-help.enable = true;
      cmp-dictionary.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        # settings.mapping =
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "luasnip"; }
        ];
      };

    };
  };
}
