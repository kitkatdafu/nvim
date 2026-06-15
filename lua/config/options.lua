-- vim.opt settings — sensible defaults tuned for Python / AI-ML development.
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- avoid layout shift when signs appear
opt.cursorline = true
opt.termguicolors = true -- 24-bit color (required by the cute theme)
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.colorcolumn = "88" -- Ruff/Black default line length
opt.showmode = false -- mode is in the statusline

-- Indentation (PEP 8: 4 spaces, no tabs)
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Files / undo
opt.swapfile = false
opt.undofile = true -- persistent undo across sessions
opt.updatetime = 250
opt.timeoutlen = 400 -- snappier which-key popup

-- Editing
opt.clipboard = "unnamedplus" -- use system clipboard
opt.mouse = "a"
opt.completeopt = "menu,menuone,noselect,fuzzy" -- 0.11 native 'fuzzy' completion
opt.confirm = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Diagnostics (0.11: virtual_text is opt-in; jump API replaces goto_next/prev)
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})
