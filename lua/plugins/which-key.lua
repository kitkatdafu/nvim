-- Keybinding hints (which-key v3). Groups mirror the <leader> namespaces.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>a", group = "AI (copilot)" },
      { "<leader>c", group = "code / lsp" },
      { "<leader>d", group = "debug" },
      { "<leader>f", group = "find" },
      { "<leader>h", group = "git hunk" },
      { "<leader>m", group = "markdown" },
      { "<leader>r", group = "run / uv" },
      { "<leader>t", group = "test" },
      { "<leader>w", group = "window" },
      { "<leader>x", group = "diagnostics / trouble" },
      { "<leader><tab>", group = "tabs" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer-local keymaps (which-key)",
    },
  },
}
