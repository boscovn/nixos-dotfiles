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
      # servers for languages commonly embedded in markdown code blocks
      bashls.enable = true;
      lua_ls.enable = true;
      pyright.enable = true;
    };
  };
  # otter does nothing until activated per buffer: it extracts code blocks
  # embedded in the host language and attaches LSPs for them.
  autoCmd = [
    {
      event = "FileType";
      pattern = [
        "markdown"
        "quarto"
      ];
      callback.__raw = ''
        function()
          require("otter").activate({ "go", "nix", "rust", "c", "cpp", "yaml", "json", "bash", "lua", "python" }, true, true, nil)
        end
      '';
    }
    {
      # Embedded code in nix strings, e.g. `/* lua */ '''...'''` or shell in
      # writeShellScript/buildPhase (from treesitter's nix injections).
      event = "FileType";
      pattern = "nix";
      callback.__raw = ''
        function()
          require("otter").activate({ "bash", "lua", "python", "json", "yaml", "c", "cpp", "go", "rust" }, true, true, nil)
        end
      '';
    }
  ];
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
    otter = {
      enable = true;
      settings = {
        buffers.set_filetype = true;
        handle_leading_whitespace = true;
      };
    };
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
