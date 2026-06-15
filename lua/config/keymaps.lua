-- Global, non-plugin keymaps. Plugin-specific maps live with their plugin spec.
-- NOTE: commenting is BUILT-IN on nvim 0.10+/0.11 — `gcc` toggles a line, `gc` is
-- the operator (gcip, gcG) and works in visual mode. No Comment.nvim needed.
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- jk exits insert mode (type the two keys quickly)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Cheatsheet of this config's keymaps (<F1> or :Cheatsheet)
map("n", "<F1>", function()
  require("cute.cheatsheet").toggle()
end, { desc = "Toggle cheatsheet" })
vim.api.nvim_create_user_command("Cheatsheet", function()
  require("cute.cheatsheet").toggle()
end, { desc = "Toggle keymap cheatsheet" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Window splits  (<leader>w = window)
map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Split window vertically" })
map("n", "<leader>ws", "<cmd>split<cr>", { desc = "Split window horizontally" })
map("n", "<leader>wc", "<cmd>close<cr>", { desc = "Close window" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "Close other windows" })

-- Tabs  (<leader><Tab> = tabs;  gt / gT also switch tabs, built-in)
map("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New tab" })
map("n", "<leader><tab>c", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close other tabs" })

-- Keep cursor centered on big jumps / search results
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move selected lines up/down (auto-reindent)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Paste over selection without clobbering the unnamed register
map("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })

-- Quick window resize
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Terminal: toggle a bottom-split terminal with ~ (Shift+`).  The shell persists
-- across toggles; <Esc><Esc> leaves terminal mode, then ~ hides the window.
do
  local t = { win = nil, buf = nil }
  local function toggle_term()
    -- Visible? Hide it — but never try to close the last window (E444).
    if t.win and vim.api.nvim_win_is_valid(t.win) then
      if #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_hide(t.win)
        t.win = nil
      end
      return
    end
    -- Open a bottom split, reusing the live shell or spawning a fresh one.
    vim.cmd("botright 15split")
    t.win = vim.api.nvim_get_current_win()
    if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
      vim.api.nvim_win_set_buf(t.win, t.buf)
    else
      vim.cmd.terminal()
      t.buf = vim.api.nvim_get_current_buf()
      -- When the shell exits, drop the dead buffer so the next ~ spawns anew.
      vim.api.nvim_create_autocmd("TermClose", {
        buffer = t.buf,
        once = true,
        callback = function()
          local buf = t.buf
          vim.schedule(function()
            if t.win and vim.api.nvim_win_is_valid(t.win) then
              pcall(vim.api.nvim_win_close, t.win, true)
            end
            if buf and vim.api.nvim_buf_is_valid(buf) then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
            t.win, t.buf = nil, nil
          end)
        end,
      })
    end
    vim.cmd.startinsert()
  end
  map("n", "~", toggle_term, { desc = "Toggle terminal (bottom split)" })
end

-- Terminal: escape to normal mode
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
