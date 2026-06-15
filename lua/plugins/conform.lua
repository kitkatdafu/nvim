-- Formatting — conform.nvim driving ruff (format + import sorting), format-on-save.
-- Order matters: organize imports first, then format. ruff must be on PATH.
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "never" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer/range (ruff)",
    },
    {
      "<leader>cF",
      function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("format-on-save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
      end,
      desc = "Toggle format-on-save",
    },
  },
  opts = {
    formatters_by_ft = {
      python = { "ruff_organize_imports", "ruff_format" },
      lua = { "stylua" }, -- if stylua is installed; harmless otherwise
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 1000, lsp_format = "never" }
    end,
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
