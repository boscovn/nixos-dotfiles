{
  lib,
  pkgs,
  ...
}:
{
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
      rust_analyzer.enable = true;
    };
  };
  colorschemes.tokyonight.enable = true;
  extraPlugins = [ pkgs.vimPlugins.plenary-nvim ];
  # rust-analyzer shells out to cargo/rustc to resolve the project's sysroot.
  extraPackages = [
    pkgs.cargo
    pkgs.rustc
  ];
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
    dap.enable = true;
    dap-ui.enable = true;
    dap-go.enable = true;
    blink-cmp.enable = true;
  };
}
