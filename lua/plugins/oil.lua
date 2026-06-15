-- File explorer that lets you edit the filesystem like a normal buffer.
return {
  "stevearc/oil.nvim",
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  lazy = false, -- the author recommends against lazy-loading oil
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = true, -- replace netrw
    view_options = { show_hidden = true },
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
  },
}
