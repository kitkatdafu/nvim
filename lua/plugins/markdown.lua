-- Advanced Markdown editing.
--   • render-markdown.nvim — in-buffer rendering of headings, lists, code blocks,
--     tables, callouts AND LaTeX math ($…$ / $$…$$). Math needs BOTH the `latex`
--     treesitter parser (auto-installed when the tree-sitter CLI is present) and
--     a converter on PATH — `utftex`, or `latex2text` from `uv tool install
--     pylatexenc`; missing either, math just shows as raw source (graceful).
--   • vim-table-mode — auto-create / auto-align GitHub-flavored tables: toggle it,
--     then typing `|` builds and realigns the table as you go.
-- Markdown LSP completion (links, headings, refs) comes from `marksman`
-- (see lua/plugins/lsp.lua); snippets come from friendly-snippets via blink.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Complete callouts/checkboxes via blink, and link/heading refs via LSP.
      completions = { blink = { enabled = true }, lsp = { enabled = true } },
      -- Render $…$ / $$…$$ to readable unicode (converter defaults to utftex,
      -- then latex2text).
      latex = { enabled = true },
    },
    keys = {
      { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle live render" },
    },
  },
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown", "markdown.mdx" },
    cmd = { "TableModeToggle", "TableModeEnable", "TableModeRealign", "Tableize" },
    init = function()
      -- GitHub-flavored Markdown tables: `|` corners, `-` header fill.
      vim.g.table_mode_corner = "|"
      vim.g.table_mode_corner_corner = "|"
      vim.g.table_mode_header_fillchar = "-"
      -- Keep the plugin's default maps off the <leader> namespace (<leader>t is
      -- test). Its prefix maps (realign, row/col ops) relocate to \t; the
      -- separate "tableize by delimiter" map uses its own var → relocate too.
      vim.g.table_mode_map_prefix = "<localleader>t"
      vim.g.table_mode_tableize_d_map = "<localleader>T"
    end,
    keys = {
      { "<leader>mt", "<cmd>TableModeToggle<cr>", ft = "markdown", desc = "Toggle table mode" },
      { "<leader>mT", ":Tableize<cr>", mode = "v", ft = "markdown", desc = "Tableize selection" },
    },
  },
}
