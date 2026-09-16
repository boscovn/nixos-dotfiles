{ lib, ... }:
{
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
    {
      action = "<cmd>Telescope buffers<CR>";
      key = "<leader><leader>";
      options.desc = "Search opened buffers with telescope";
    }
    {
      action = "<cmd>Telescope grep_string<CR>";
      key = "<leader>sg";
      options.desc = "Search for a string in the project with telescope";
    }
  ];
  lsp.keymaps = [
    {
      key = "gd";
      lspBufAction = "definition";
    }
    {
      key = "grr";
      action = "<cmd>Telescope lsp_references<CR>";
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
    {
      key = "<leader>ld";
      action.__raw = ''
        function()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end
      '';
      options.desc = "Toggle diagnostics";
    }
  ];
  plugins.blink-cmp.settings.keymap = {
    "<C-d>" = [ "scroll_documentation_up" ];
    "<C-f>" = [ "scroll_documentation_down" ];
    "<C-Space>" = [ "show" ];
    "<C-e>" = [ "hide" ];
    "<Tab>" = [
      "select_next"
      "fallback"
    ];
    "<S-Tab>" = [
      "select_prev"
      "fallback"
    ];
    "<CR>" = [
      "select_and_accept"
      "fallback"
    ];
  };
}
