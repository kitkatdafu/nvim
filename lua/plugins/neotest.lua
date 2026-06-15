-- Testing — neotest with the pytest adapter.
-- uv: neotest-python auto-detects the project's `.venv` (uv's default layout),
-- so tests run under the right interpreter with no extra config. Debugging a
-- test uses nvim-dap-python (needs `uv add --dev debugpy`).
return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "mfussenegger/nvim-dap-python",
  },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end, desc = "Test nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Test file" },
    { "<leader>tA", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Test all" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show output" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
    { "<leader>tw", function() require("neotest").watch.toggle() end, desc = "Toggle watch" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop test" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          runner = "pytest",
          dap = { justMyCode = false },
        }),
      },
      output = { open_on_run = false },
      quickfix = { enabled = false },
    })
  end,
}
