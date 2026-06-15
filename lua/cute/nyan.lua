-- ============================================================================
-- Nyan-cat statusline component — a width-capped, animated reimplementation of
-- nefo-mi/nyan-modoki.vim (itself a port of TeMPOraL's nyan-mode.el).
--
-- The original plugin (installed alongside, see lua/plugins/lualine.lua) sizes
-- its bar to winwidth/2 — far too wide for a single statusline section — so this
-- module keeps nyan-modoki's exact `|<cat>-` structure and its kaomoji cat
-- faces, but at a fixed, sane width, and animates as the statusline refreshes.
-- The cat marches left→right tracking your position in the buffer (0%→100%).
-- ============================================================================
local M = {}

-- Cat face set #1 from nyan-modoki.vim (the "ﾆｬﾝ" cat), cycled for animation.
local faces = { "(*^ｰﾟ)ﾆｬﾝ", "( ^ｰ^)ﾆｬﾝ", "ﾆｬﾝ(^ｰ^ )", "ﾆｬﾝ(ﾟｰ^*)" }

local WIDTH = 12 -- trail width in cells (behind + ahead of the cat)
local tick = 0

--- Render the nyan bar as a statusline string. Use as a lualine function
--- component with `color = "CuteNyanBar"`.
---@return string
function M.render()
  tick = tick + 1
  local face = faces[(math.floor(tick / 2) % #faces) + 1]

  local total = vim.fn.line("$")
  local cur = vim.fn.line(".")
  local pos = total > 1 and math.floor((cur - 1) / (total - 1) * WIDTH) or 0
  pos = math.max(0, math.min(WIDTH, pos))

  local behind = string.rep("|", pos)
  local ahead = string.rep("-", WIDTH - pos)
  return behind .. face .. ahead
end

return M
