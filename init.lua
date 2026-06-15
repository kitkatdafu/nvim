-- ============================================================================
-- Neovim config — Python / AI-ML, uv-native, with GitHub Copilot
--   • LSP: pyrefly (types) + ruff (lint/format/imports)   • Completion: blink.cmp
--   • Jupyter: molten + jupytext + image.nvim             • Debug/Test: dap + neotest
--   • Theme: "cute" (pink light port) + nyan-cat statusline
-- Entry point: sets leaders, loads config/, bootstraps lazy.nvim, applies theme.
-- ============================================================================

-- Leaders MUST be set before lazy loads so plugin mappings register correctly.
-- <leader> = Space (global maps), <localleader> = \ (molten / Jupyter cells).
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Dedicated Python host for Neovim's remote-plugin API (molten needs pynvim +
-- jupyter_client here). Only set it if the venv actually exists, otherwise leave
-- Neovim's default python3 provider alone. See README → "Jupyter / molten setup".
local nvim_py = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
if (vim.uv or vim.loop).fs_stat(nvim_py) then
  vim.g.python3_host_prog = nvim_py
end

-- Core (non-plugin) config first.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.python") -- uv venv resolver + run/REPL keymaps

-- Bootstrap lazy.nvim (official snippet, stable branch).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "cute" } },
  checker = { enabled = true, notify = false }, -- background update check
  change_detection = { notify = false },
  ui = { border = "rounded" },
})

-- Apply the bespoke "cute" colorscheme (lua/cute/ + colors/cute.lua).
vim.o.background = "light"
pcall(vim.cmd.colorscheme, "cute")
