{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./keymaps.nix
  ];
  programs.nixvim = {
    enable = true;
    vimAlias = true;
    globals.mapleader = " ";
    opts = {
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      autoindent = true;
      breakindent = true;
    };
    lsp = {
      servers = {
        clangd.enable = true;
        gopls.enable = true;
        nixd.enable = true;
        yamlls.enable = true;
        jsonls.enable = true;
        zls.enable = true;
      };
    };
    colorschemes.tokyonight.enable = true;
    extraPlugins = [ pkgs.vimPlugins.plenary-nvim ];
    plugins = {
      nix.enable = true;
      lsp.enable = true;
      oil.enable = true;
      otter.enable = true;
      snacks = {
        enable = true;
        settings = {
          input.enabled = true;
        };
      };
      telescope.enable = true;
      web-devicons.enable = true;
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = false;
        };
      };
      which-key.enable = true;
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
          formatters_by_ft = {
            nix = [ "nixfmt" ];
          };
        };
      };
      schemastore = {
        enable = true;
        yaml.enable = true;
      };
      luasnip.enable = true;
      dap.enable = true;
      dap-ui.enable = true;
      dap-go.enable = true;
      cmp-omni.enable = true;
      cmp-dap.enable = true;
      # cmp-nvim-lsp.enable = true;
      # cmp-nvim-lsp-document-symbol.enable = true;
      # cmp-nvim-lsp-signature-help.enable = true;
      cmp-dictionary.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
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
