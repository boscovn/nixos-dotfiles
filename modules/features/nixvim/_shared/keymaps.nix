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
    {
      key = "<leader>db";
      action.__raw = ''function() require("dap").toggle_breakpoint() end'';
      options.desc = "Dap: toggle breakpoint";
    }
    {
      key = "<leader>dc";
      action.__raw = ''function() require("dap").continue() end'';
      options.desc = "Dap: start/continue";
    }
    {
      key = "<leader>di";
      action.__raw = ''function() require("dap").step_into() end'';
      options.desc = "Dap: step into";
    }
    {
      key = "<leader>do";
      action.__raw = ''function() require("dap").step_over() end'';
      options.desc = "Dap: step over";
    }
    {
      key = "<leader>dO";
      action.__raw = ''function() require("dap").step_out() end'';
      options.desc = "Dap: step out";
    }
    {
      key = "<leader>dr";
      action.__raw = ''function() require("dap").repl.toggle() end'';
      options.desc = "Dap: toggle repl";
    }
    {
      key = "<leader>dx";
      action.__raw = ''function() require("dap").terminate() end'';
      options.desc = "Dap: terminate";
    }
    {
      key = "<leader>du";
      action.__raw = ''function() require("dapui").toggle() end'';
      options.desc = "Dap: toggle ui";
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
      "snippet_forward"
      "fallback"
    ];
    "<S-Tab>" = [
      "select_prev"
      "snippet_backward"
      "fallback"
    ];
    "<CR>" = [
      "select_and_accept"
      "fallback"
    ];
  };
}
