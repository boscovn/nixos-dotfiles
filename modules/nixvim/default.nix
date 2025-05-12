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
  ];
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    opts = {
      relativenumber = true;
    };
    lsp = {
      keymaps = [
        {
          key = "gd";
          lspBufAction = "definition";
        }
        {
          key = "gD";
          lspBufAction = "references";
        }
        {
          key = "gt";
          lspBufAction = "type_definition";
        }
        {
          key = "gi";
          lspBufAction = "implementation";
        }
        {
          key = "K";
          lspBufAction = "hover";
        }
        # {
        #   action = lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count=-1, float=true }) end";
        #   key = "<leader>k";
        # }
        # {
        #   action = lib.nixvim.mkRaw "function() vim.diagnostic.jump({ count=1, float=true }) end";
        #   key = "<leader>j";
        # }
        {
          action = "<CMD>LspStop<Enter>";
          key = "<leader>lx";
        }
        {
          action = "<CMD>LspStart<Enter>";
          key = "<leader>ls";
        }
        {
          action = "<CMD>LspRestart<Enter>";
          key = "<leader>lr";
        }
        # {
        #   action = lib.nixvim.mkRaw "require('telescope.builtin').lsp_definitions";
        #   key = "gd";
        # }
        {
          action = "<CMD>Lspsaga hover_doc<Enter>";
          key = "K";
        }
      ];

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
      lsp.enable = true;
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
