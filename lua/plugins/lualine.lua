-- Statusline — lualine with the cute theme and the nyan-cat position indicator.
-- nefo-mi/nyan-modoki.vim (the Neovim port of nyan-mode.el) is installed so its
-- g:NyanModoki() is available; the statusline uses a width-capped, cute-themed
-- component (lua/cute/nyan.lua) faithful to it so it doesn't eat the whole bar.
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "nefo-mi/nyan-modoki.vim", -- the nyan-mode port (provides g:NyanModoki())
  },
  init = function()
    vim.g.nyan_modoki_select_cat_face_number = 1 -- the "ﾆｬﾝ" cat
  end,
  opts = function()
    local nyan = require("cute.nyan")
    return {
      options = {
        theme = require("cute.lualine"),
        globalstatus = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        refresh = { statusline = 250 }, -- keeps the nyan cat animating
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = "  ", newfile = " " } },
        },
        lualine_x = {
          { nyan.render, color = "CuteNyanBar", padding = { left = 1, right = 1 } },
          "diagnostics",
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      extensions = { "oil", "trouble", "lazy", "nvim-dap-ui", "quickfix" },
    }
  end,
}
