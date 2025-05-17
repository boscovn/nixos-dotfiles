{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.nixvim = {

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
    lsp.keymaps = [

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
        action = "<CMD>Lsp hover_doc<Enter>";
        key = "K";
      }
    ];
    plugins.cmp.settings.mapping = {
      "<C-d>" = "cmp.mapping.scroll_docs(-4)";
      "<C-f>" = "cmp.mapping.scroll_docs(4)";
      "<C-Space>" = "cmp.mapping.complete()";
      "<C-e>" = "cmp.mapping.close()";
      "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
      "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
      "<CR>" = "cmp.mapping.confirm({ select = true })";
    };
  };
}
