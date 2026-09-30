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
    exrc = true;
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
        function(args)
          -- skip scratch buffers such as LSP hover floats (filetype markdown)
          if vim.bo[args.buf].buftype ~= "" then return end
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
        function(args)
          if vim.bo[args.buf].buftype ~= "" then return end
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
      # activates on every LSP attach, including otter-ls itself and hover
      # floats; we activate explicitly per filetype below instead
      autoActivate = false;
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
    # dap-python's own extraConfig already calls
    # `require("dap-python").setup(adapterPythonPath, settings)`; leaving
    # callSetup at its default (false) avoids a second, malformed call
    # (nixvim's generic callSetup would pass `settings` as the path arg).
    dap-python.enable = true;
    # Gives lua_ls the `vim` global/runtime API wherever a Lua file is
    # opened (init.lua, plugin dirs, or a project-local .nvim.lua under
    # `exrc`) by lazily injecting $VIMRUNTIME as a library per workspace.
    lazydev = {
      enable = true;
      settings.integrations.cmp = false; # we use blink-cmp, not nvim-cmp
    };
    blink-cmp = {
      enable = true;
      settings.sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
          "lazydev"
        ];
        providers.lazydev = {
          name = "LazyDev";
          module = "lazydev.integrations.blink";
          score_offset = 100; # show lazydev's vim/module completions first
        };
      };
    };
  };
  # nvim-dap-ui doesn't open/close itself; hook it to dap's lifecycle events.
  extraConfigLua = ''
    do
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end
  '';
}
