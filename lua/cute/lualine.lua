-- Lualine theme matching the "cute" colorscheme (pink statusline per mode).
local p = require("cute").palette

return {
  normal = {
    a = { fg = p.bg, bg = p.pink, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_pink },
    c = { fg = p.fg, bg = p.bg_alt },
  },
  insert = {
    a = { fg = p.bg, bg = p.rose, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_pink },
    c = { fg = p.fg, bg = p.bg_alt },
  },
  visual = {
    a = { fg = p.bg, bg = p.purple2, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_pink },
    c = { fg = p.fg, bg = p.bg_alt },
  },
  replace = {
    a = { fg = p.bg, bg = p.error, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_pink },
    c = { fg = p.fg, bg = p.bg_alt },
  },
  command = {
    a = { fg = p.bg, bg = p.purple, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_pink },
    c = { fg = p.fg, bg = p.bg_alt },
  },
  inactive = {
    a = { fg = p.purple2, bg = p.bg_alt, gui = "bold" },
    b = { fg = p.purple2, bg = p.bg_alt },
    c = { fg = p.pink_soft, bg = p.bg_alt },
  },
}
