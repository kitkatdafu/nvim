-- Autocommands.
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight yanked text (0.11: vim.hl, not the deprecated vim.highlight).
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "CuteYank", timeout = 200 })
  end,
})

-- Trim trailing whitespace on save (skip filetypes where it's meaningful).
autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  pattern = "*",
  callback = function(ev)
    if vim.tbl_contains({ "markdown", "diff", "gitcommit" }, vim.bo[ev.buf].filetype) then
      return
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Return to last edit position when reopening a file.
autocmd("BufReadPost", {
  group = augroup("last_loc", { clear = true }),
  callback = function(ev)
    local exclude = { "gitcommit" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close noisy/utility buffers with `q`.
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = {
    "help",
    "qf",
    "man",
    "lspinfo",
    "checkhealth",
    "neotest-output",
    "neotest-summary",
    "dap-float",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})
