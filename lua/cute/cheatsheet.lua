-- ============================================================================
-- A cute-themed cheatsheet of THIS config's keymaps, in a floating window.
-- Toggle with <F1> or :Cheatsheet  (q / <Esc> / <F1> to close).
-- Two balanced columns when the terminal is wide enough, else one.
-- ============================================================================
local M = {}

-- localleader is "\"
local sections = {
  { "▸ General", {
    { "<Esc>", "Clear search highlight" },
    { "jk", "Exit insert mode" },
    { "<F1>", "Toggle this cheatsheet" },
    { "<leader>?", "Buffer-local keys (which-key)" },
    { "-", "File explorer (oil)" },
    { "gcc / gc", "Comment line / motion" },
    { "<leader>p", "Paste without yanking" },
  } },
  { "▸ Windows · Tabs · Term", {
    { "<C-hjkl>", "Move between windows" },
    { "<leader>wv / ws", "Split vert / horizontal" },
    { "<leader>wc / wo", "Close / only window" },
    { "<leader><Tab>n", "New tab" },
    { "<leader><Tab>][", "Next / prev tab" },
    { "gt / gT", "Switch tab (built-in)" },
    { "~", "Toggle terminal (Shift+`)" },
    { "<Esc><Esc>", "Exit terminal mode" },
  } },
  { "▸ Find — <leader>f", {
    { "ff / <Space>", "Find files" },
    { "fg", "Live grep" },
    { "fb", "Buffers" },
    { "fr", "Recent files" },
    { "fh", "Help tags" },
    { "fd", "Diagnostics" },
    { "fs", "Document symbols" },
    { "fk", "Keymaps" },
    { "/", "Search in buffer" },
  } },
  { "▸ Code / LSP — <leader>c", {
    { "gd / gD / gy", "Definition / decl / type" },
    { "K", "Hover (pyrefly)" },
    { "grn / grr / gra", "Rename / refs / action" },
    { "cr / ca", "Rename / code action" },
    { "cd", "Line diagnostics" },
    { "co", "Organize imports (ruff)" },
    { "cf / cF", "Format / toggle on-save" },
    { "ci", "Toggle inlay hints" },
    { "cs / cl", "Symbols / refs (Trouble)" },
    { "[d / ]d", "Prev / next diagnostic" },
  } },
  { "▸ Run / uv — <leader>r", {
    { "rr", "Run file (uv run)" },
    { "ri", "ipython REPL (uv run)" },
    { "rs", "uv sync" },
    { "ra", "uv add <pkg>" },
  } },
  { "▸ Test — <leader>t", {
    { "tt / tf / tA", "Nearest / file / all" },
    { "td", "Debug nearest test" },
    { "ts", "Toggle summary" },
    { "to / tO", "Output / panel" },
    { "tw", "Toggle watch" },
  } },
  { "▸ Debug — <leader>d", {
    { "db / dB", "Breakpoint / conditional" },
    { "dc  <F5>", "Continue / start" },
    { "di / do / dO", "Step into / over / out" },
    { "dr / du", "REPL / UI" },
    { "dt", "Terminate" },
    { "dn / df", "Debug test method / class" },
  } },
  { "▸ AI · Copilot — <leader>a", {
    { "aa", "Toggle chat" },
    { "am", "Pick model" },
    { "ap / aq", "Prompts / quick chat" },
    { "ax", "Reset chat" },
    { "(v) ae af at ar", "Explain fix tests review" },
  } },
  { "▸ Git hunks — <leader>h", {
    { "[c / ]c", "Prev / next hunk" },
    { "hs / hr", "Stage / reset hunk" },
    { "hS", "Stage buffer" },
    { "hp / hb", "Preview / blame" },
    { "hd", "Diff this" },
  } },
  { "▸ Diagnostics — <leader>x", {
    { "xx / xX", "All / buffer (Trouble)" },
    { "xL / xQ", "Loclist / quickfix" },
    { "xt", "Todos (Trouble)" },
    { "[t / ]t", "Prev / next todo" },
  } },
  { "▸ Jupyter · molten (\\)", {
    { "\\mi / \\md", "Init / deinit kernel" },
    { "\\e", "Eval operator (\\eip)" },
    { "\\rl", "Eval line" },
    { "(v) \\r", "Eval selection" },
    { "\\rr / \\ri", "Re-eval / interrupt" },
    { "\\oh / \\os", "Hide / enter output" },
    { "\\oi", "Image popup" },
    { "[x / ]x", "Prev / next cell" },
  } },
  { "▸ Markdown — <leader>m", {
    { "mr", "Toggle live render" },
    { "mt / mT", "Table mode / tableize" },
    { "$x$ / $$x$$", "Inline / block math" },
    { "K / gd", "Hover / goto (marksman)" },
  } },
  { "▸ Completion (blink)", {
    { "<Tab> / <CR>", "Accept selection" },
    { "<C-n> / <C-p>", "Next / prev item" },
    { "<C-Space>", "Open menu / docs" },
    { "<C-e>", "Close menu" },
    { "<C-k>", "Toggle signature" },
  } },
}

local KEY_W = 17 -- key column width (display cells)
local GAP = 4 -- gap between the two columns
local state = { win = nil }

-- Turn a section into renderable rows: { text, kind, kstart, kend } (byte cols).
local function build_block(title, entries)
  local block = { { text = title, kind = "header" } }
  for _, e in ipairs(entries) do
    local key, desc = e[1], e[2]
    local pad = math.max(1, KEY_W - vim.fn.strdisplaywidth(key))
    block[#block + 1] = {
      text = "  " .. key .. string.rep(" ", pad) .. desc,
      kind = "key",
      kstart = 2,
      kend = 2 + #key,
    }
  end
  block[#block + 1] = { text = "", kind = "blank" }
  return block
end

function M.open()
  local p = require("cute").palette
  vim.api.nvim_set_hl(0, "CuteCheatHeader", { fg = p.purple, bold = true })
  vim.api.nvim_set_hl(0, "CuteCheatKey", { fg = p.pink, bold = true })

  -- Build blocks + measure the widest row.
  local blocks, maxw = {}, 0
  for _, s in ipairs(sections) do
    local b = build_block(s[1], s[2])
    blocks[#blocks + 1] = b
    for _, row in ipairs(b) do
      maxw = math.max(maxw, vim.fn.strdisplaywidth(row.text))
    end
  end

  -- Two columns if the terminal is wide enough, else one.
  local two = vim.o.columns >= (2 * maxw + GAP + 4)
  local left, right, lh, rh = {}, {}, 0, 0
  for _, b in ipairs(blocks) do
    if two and lh > rh then
      vim.list_extend(right, b)
      rh = rh + #b
    else
      vim.list_extend(left, b)
      lh = lh + #b
    end
  end

  -- Zip columns into lines, recording highlight spans (byte columns).
  local lines, hls = {}, {}
  local rows = math.max(#left, #right)
  for i = 1, rows do
    local l = left[i] or { text = "", kind = "blank" }
    local r = right[i] or { text = "", kind = "blank" }
    local lpad = l.text .. string.rep(" ", maxw - vim.fn.strdisplaywidth(l.text) + GAP)
    local line = " " .. lpad .. r.text
    lines[#lines + 1] = line
    local row, loff, roff = i - 1, 1, 1 + #lpad
    if l.kind == "header" then
      hls[#hls + 1] = { row, loff, loff + #l.text, "CuteCheatHeader" }
    elseif l.kind == "key" then
      hls[#hls + 1] = { row, loff + l.kstart, loff + l.kend, "CuteCheatKey" }
    end
    if r.kind == "header" then
      hls[#hls + 1] = { row, roff, roff + #r.text, "CuteCheatHeader" }
    elseif r.kind == "key" then
      hls[#hls + 1] = { row, roff + r.kstart, roff + r.kend, "CuteCheatKey" }
    end
  end

  -- Buffer.
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("cute_cheatsheet")
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  -- Float window, docked to the lower-right corner.
  local width = math.min((two and (1 + maxw + GAP + maxw) or (1 + maxw)) + 1, vim.o.columns - 2)
  local height = math.min(rows, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    -- Dock to the lower-right corner so the editing area on the left stays clear.
    row = math.max(0, vim.o.lines - height - 4),
    col = math.max(0, vim.o.columns - width - 2),
    style = "minimal",
    border = "rounded",
    title = " 🌸 cute.nvim cheatsheet ",
    title_pos = "center",
    footer = " q / <Esc> to close ",
    footer_pos = "center",
  })
  state.win = win
  vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle"
  vim.wo[win].cursorline = false

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    state.win = nil
  end
  for _, k in ipairs({ "q", "<Esc>", "<F1>" }) do
    vim.keymap.set("n", k, close, { buffer = buf, nowait = true, silent = true })
  end
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  else
    M.open()
  end
end

return M
