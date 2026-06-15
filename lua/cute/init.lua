-- ============================================================================
-- "cute" — a Neovim port of WebFreak's "Cute Pink Light" VS Code theme.
-- Palette extracted from webfreak.cute-theme v0.0.4 (themes/cute.json):
--   • white background + pink UI chrome (the theme's identity)
--   • VS Code "Light+" syntax colors (what the theme actually ships)
-- Light theme. `:colorscheme cute`. Lualine theme: require("cute.lualine").
-- ============================================================================
local M = {}

-- Palette --------------------------------------------------------------------
M.palette = {
  -- base / chrome (the "cute pink" identity)
  bg = "#ffffff",
  fg = "#333333",
  bg_dim = "#fff7fa", -- near-white pink: floats, cursorline, menus
  bg_alt = "#fceaf1", -- very light pink: sidebars, inactive tabs, statusline c
  bg_pink = "#fcdee9", -- light pink: active tab, widgets, statusline b
  pink = "#ff4574", -- hot pink: primary accent, statusline normal
  rose = "#ff7ba2", -- rose: borders, insert mode, selection accent
  pink_soft = "#ffb1b7", -- soft pink: line numbers, subtle borders
  pink_mid = "#f4b4cc", -- medium pink: visual selection, pmenu sel
  peach = "#ffd5bd", -- peach: search match, references
  salmon = "#fac3c0", -- salmon: find highlight
  plum = "#2e2638", -- dark plum: dark accents
  purple = "#39007f", -- purple: command mode, special
  purple2 = "#974283", -- muted purple: hints, comments-special
  purple_dk = "#210049", -- dark purple: titles
  faint = "#c8a9bd", -- faded pink-grey: unnecessary code / ghost text

  -- syntax (VS Code Light+, as shipped by the theme)
  comment = "#008000", -- green
  keyword = "#0000ff", -- blue: def/class/storage/builtins/self
  control = "#af00db", -- purple: if/for/return/import control flow
  string = "#a31515", -- dark red
  number = "#098658", -- green
  func = "#795e26", -- olive: functions, decorators
  type = "#267f99", -- teal: types/classes/namespaces
  variable = "#001080", -- navy: variables, params, attributes
  constant = "#328267", -- teal-green: named constants / enum members
  tag = "#800000", -- maroon: tags, markdown headings
  attribute = "#ff0000", -- red: html attrs, escape sequences
  regexp = "#811f3f",
  operator = "#000000",

  -- state
  error = "#e51400",
  warn = "#b8860b",
  info = "#316bcd",
  hint = "#974283",
  add = "#587c0c",
  change = "#a06000",
  delete = "#ad0707",
}

function M.load()
  local p = M.palette
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.o.background = "light"
  vim.g.colors_name = "cute"

  local groups = {
    -- Editor UI ------------------------------------------------------------
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_dim },
    FloatBorder = { fg = p.rose, bg = p.bg_dim },
    FloatTitle = { fg = p.pink, bg = p.bg_dim, bold = true },
    ColorColumn = { bg = p.bg_alt },
    Cursor = { fg = p.bg, bg = p.pink },
    CursorLine = { bg = p.bg_dim },
    CursorColumn = { bg = p.bg_dim },
    CursorLineNr = { fg = p.pink, bold = true },
    LineNr = { fg = p.pink_soft },
    LineNrAbove = { fg = p.pink_soft },
    LineNrBelow = { fg = p.pink_soft },
    SignColumn = { bg = "NONE" },
    FoldColumn = { fg = p.pink_soft },
    Folded = { fg = p.purple2, bg = p.bg_alt },
    WinSeparator = { fg = p.pink_mid },
    VertSplit = { fg = p.pink_mid },
    NonText = { fg = p.pink_soft },
    Whitespace = { fg = p.pink_soft },
    SpecialKey = { fg = p.pink_soft },
    EndOfBuffer = { fg = p.bg_alt },
    Visual = { bg = p.pink_mid },
    VisualNOS = { bg = p.pink_mid },
    Search = { fg = p.fg, bg = p.peach },
    IncSearch = { fg = p.bg, bg = p.pink },
    CurSearch = { fg = p.bg, bg = p.pink },
    MatchParen = { bg = p.pink_mid, bold = true },
    Pmenu = { fg = p.fg, bg = p.bg_dim },
    PmenuSel = { fg = p.fg, bg = p.pink_mid, bold = true },
    PmenuSbar = { bg = p.bg_alt },
    PmenuThumb = { bg = p.rose },
    PmenuKind = { fg = p.type, bg = p.bg_dim },
    PmenuExtra = { fg = p.purple2, bg = p.bg_dim },
    WildMenu = { fg = p.fg, bg = p.pink_mid },
    StatusLine = { fg = p.fg, bg = p.bg_pink },
    StatusLineNC = { fg = p.purple2, bg = p.bg_alt },
    TabLine = { fg = p.fg, bg = p.bg_alt },
    TabLineSel = { fg = p.fg, bg = p.bg_pink, bold = true },
    TabLineFill = { bg = p.bg_alt },
    Winbar = { fg = p.purple2, bg = p.bg },
    WinbarNC = { fg = p.pink_soft, bg = p.bg },
    Title = { fg = p.pink, bold = true },
    Directory = { fg = p.type, bold = true },
    ErrorMsg = { fg = p.error },
    WarningMsg = { fg = p.warn },
    ModeMsg = { fg = p.fg, bold = true },
    MoreMsg = { fg = p.pink },
    Question = { fg = p.pink },
    Conceal = { fg = p.purple2 },
    QuickFixLine = { bg = p.pink_mid },
    CuteYank = { fg = p.fg, bg = p.peach },

    -- Syntax (legacy groups) ----------------------------------------------
    Comment = { fg = p.comment, italic = true },
    Constant = { fg = p.number },
    String = { fg = p.string },
    Character = { fg = p.keyword },
    Number = { fg = p.number },
    Float = { fg = p.number },
    Boolean = { fg = p.keyword },
    Identifier = { fg = p.variable },
    Function = { fg = p.func },
    Statement = { fg = p.control },
    Conditional = { fg = p.control },
    Repeat = { fg = p.control },
    Label = { fg = p.control },
    Operator = { fg = p.operator },
    Keyword = { fg = p.keyword },
    Exception = { fg = p.control },
    PreProc = { fg = p.keyword },
    Include = { fg = p.control },
    Define = { fg = p.keyword },
    Macro = { fg = p.keyword },
    PreCondit = { fg = p.keyword },
    Type = { fg = p.type },
    StorageClass = { fg = p.keyword },
    Structure = { fg = p.type },
    Typedef = { fg = p.type },
    Special = { fg = p.purple2 },
    SpecialChar = { fg = p.attribute },
    Tag = { fg = p.tag },
    Delimiter = { fg = p.fg },
    SpecialComment = { fg = p.purple2 },
    Debug = { fg = p.tag },
    Underlined = { fg = p.pink, underline = true },
    Error = { fg = p.error },
    Todo = { fg = p.bg, bg = p.pink, bold = true },

    -- Treesitter ----------------------------------------------------------
    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { fg = p.comment, italic = true },
    ["@comment.error"] = { fg = p.error },
    ["@comment.warning"] = { fg = p.warn },
    ["@comment.todo"] = { link = "Todo" },
    ["@comment.note"] = { fg = p.info, bold = true },
    ["@keyword"] = { fg = p.keyword },
    ["@keyword.function"] = { fg = p.keyword },
    ["@keyword.operator"] = { fg = p.keyword }, -- and / or / not / in / is
    ["@keyword.return"] = { fg = p.control },
    ["@keyword.conditional"] = { fg = p.control },
    ["@keyword.repeat"] = { fg = p.control },
    ["@keyword.import"] = { fg = p.control },
    ["@keyword.exception"] = { fg = p.control },
    ["@keyword.coroutine"] = { fg = p.control }, -- async / await
    ["@keyword.directive"] = { fg = p.keyword },
    ["@conditional"] = { fg = p.control },
    ["@repeat"] = { fg = p.control },
    ["@exception"] = { fg = p.control },
    ["@string"] = { fg = p.string },
    ["@string.documentation"] = { fg = p.string },
    ["@string.regexp"] = { fg = p.regexp },
    ["@string.escape"] = { fg = p.attribute },
    ["@string.special"] = { fg = p.attribute },
    ["@string.special.url"] = { fg = p.info, underline = true },
    ["@character"] = { fg = p.keyword },
    ["@character.special"] = { fg = p.attribute },
    ["@number"] = { fg = p.number },
    ["@number.float"] = { fg = p.number },
    ["@boolean"] = { fg = p.keyword },
    ["@constant"] = { fg = p.constant },
    ["@constant.builtin"] = { fg = p.keyword }, -- None / True / False
    ["@constant.macro"] = { fg = p.keyword },
    ["@function"] = { fg = p.func },
    ["@function.call"] = { fg = p.func },
    ["@function.method"] = { fg = p.func },
    ["@function.method.call"] = { fg = p.func },
    ["@function.builtin"] = { fg = p.func },
    ["@function.macro"] = { fg = p.func },
    ["@constructor"] = { fg = p.type },
    ["@variable"] = { fg = p.variable },
    ["@variable.builtin"] = { fg = p.keyword }, -- self / cls / __name__
    ["@variable.parameter"] = { fg = p.variable },
    ["@variable.parameter.builtin"] = { fg = p.variable },
    ["@variable.member"] = { fg = p.variable }, -- obj.attribute
    ["@property"] = { fg = p.variable },
    ["@field"] = { fg = p.variable },
    ["@type"] = { fg = p.type },
    ["@type.builtin"] = { fg = p.type }, -- int / str / list
    ["@type.definition"] = { fg = p.type },
    ["@type.qualifier"] = { fg = p.keyword },
    ["@attribute"] = { fg = p.func }, -- @decorator
    ["@attribute.builtin"] = { fg = p.func },
    ["@module"] = { fg = p.type }, -- import module names
    ["@namespace"] = { fg = p.type },
    ["@operator"] = { fg = p.operator },
    ["@punctuation.delimiter"] = { fg = p.fg },
    ["@punctuation.bracket"] = { fg = p.fg },
    ["@punctuation.special"] = { fg = p.control }, -- f-string { }
    ["@tag"] = { fg = p.tag },
    ["@tag.attribute"] = { fg = p.attribute },
    ["@tag.delimiter"] = { fg = p.fg },
    ["@label"] = { fg = p.control },
    ["@markup.heading"] = { fg = p.tag, bold = true },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.link"] = { fg = p.pink, underline = true },
    ["@markup.link.label"] = { fg = p.pink },
    ["@markup.link.url"] = { fg = p.info, underline = true },
    ["@markup.raw"] = { fg = p.string }, -- `inline code`
    ["@markup.raw.block"] = { fg = p.fg },
    ["@markup.list"] = { fg = p.info },
    ["@markup.quote"] = { fg = p.purple2, italic = true },
    ["@diff.plus"] = { fg = p.add },
    ["@diff.minus"] = { fg = p.delete },
    ["@diff.delta"] = { fg = p.change },

    -- LSP semantic tokens --------------------------------------------------
    ["@lsp.type.class"] = { fg = p.type },
    ["@lsp.type.decorator"] = { fg = p.func },
    ["@lsp.type.enum"] = { fg = p.type },
    ["@lsp.type.enumMember"] = { fg = p.constant },
    ["@lsp.type.function"] = { fg = p.func },
    ["@lsp.type.method"] = { fg = p.func },
    ["@lsp.type.interface"] = { fg = p.type },
    ["@lsp.type.namespace"] = { fg = p.type },
    ["@lsp.type.parameter"] = { fg = p.variable },
    ["@lsp.type.property"] = { fg = p.variable },
    ["@lsp.type.variable"] = { fg = p.variable },
    ["@lsp.type.type"] = { fg = p.type },
    ["@lsp.type.keyword"] = { fg = p.keyword },
    ["@lsp.type.string"] = { fg = p.string },
    ["@lsp.type.number"] = { fg = p.number },
    ["@lsp.typemod.variable.readonly"] = { fg = p.constant },
    ["@lsp.typemod.variable.global"] = { fg = p.variable },
    ["@lsp.typemod.function.builtin"] = { fg = p.func },

    -- Diagnostics ----------------------------------------------------------
    DiagnosticError = { fg = p.error },
    DiagnosticWarn = { fg = p.warn },
    DiagnosticInfo = { fg = p.info },
    DiagnosticHint = { fg = p.hint },
    DiagnosticOk = { fg = p.add },
    DiagnosticVirtualTextError = { fg = p.error, bg = "NONE" },
    DiagnosticVirtualTextWarn = { fg = p.warn, bg = "NONE" },
    DiagnosticVirtualTextInfo = { fg = p.info, bg = "NONE" },
    DiagnosticVirtualTextHint = { fg = p.hint, bg = "NONE" },
    DiagnosticUnderlineError = { undercurl = true, sp = p.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.warn },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.info },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.hint },
    DiagnosticUnnecessary = { fg = p.faint },
    DiagnosticDeprecated = { strikethrough = true, sp = p.error },

    -- LSP refs / hints -----------------------------------------------------
    LspReferenceText = { bg = p.bg_pink },
    LspReferenceRead = { bg = p.bg_pink },
    LspReferenceWrite = { bg = p.peach },
    LspSignatureActiveParameter = { fg = p.pink, bold = true },
    LspInlayHint = { fg = p.purple2, bg = p.bg_alt, italic = true },
    LspCodeLens = { fg = p.purple2 },

    -- Git ------------------------------------------------------------------
    GitSignsAdd = { fg = p.add },
    GitSignsChange = { fg = p.change },
    GitSignsDelete = { fg = p.delete },
    GitSignsAddNr = { fg = p.add },
    GitSignsChangeNr = { fg = p.change },
    GitSignsDeleteNr = { fg = p.delete },
    Added = { fg = p.add },
    Changed = { fg = p.change },
    Removed = { fg = p.delete },
    DiffAdd = { bg = "#eaf3da" },
    DiffChange = { bg = "#fdeede" },
    DiffDelete = { fg = p.delete, bg = "#fbe0e0" },
    DiffText = { bg = "#fcd0cc" },

    -- Telescope ------------------------------------------------------------
    TelescopeNormal = { fg = p.fg, bg = p.bg_dim },
    TelescopeBorder = { fg = p.rose, bg = p.bg_dim },
    TelescopePromptNormal = { fg = p.fg, bg = p.bg_pink },
    TelescopePromptBorder = { fg = p.pink_mid, bg = p.bg_pink },
    TelescopePromptTitle = { fg = p.bg, bg = p.pink, bold = true },
    TelescopeResultsTitle = { fg = p.bg, bg = p.rose, bold = true },
    TelescopePreviewTitle = { fg = p.bg, bg = p.purple2, bold = true },
    TelescopeSelection = { bg = p.pink_mid, bold = true },
    TelescopeSelectionCaret = { fg = p.pink, bg = p.pink_mid },
    TelescopeMatching = { fg = p.pink, bold = true },
    TelescopePromptPrefix = { fg = p.pink },

    -- blink.cmp ------------------------------------------------------------
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_dim },
    BlinkCmpMenuBorder = { fg = p.rose, bg = p.bg_dim },
    BlinkCmpMenuSelection = { bg = p.pink_mid, bold = true },
    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelMatch = { fg = p.pink, bold = true },
    BlinkCmpLabelDeprecated = { fg = p.faint, strikethrough = true },
    BlinkCmpLabelDetail = { fg = p.purple2 },
    BlinkCmpKind = { fg = p.type },
    BlinkCmpKindCopilot = { fg = p.pink },
    BlinkCmpDoc = { fg = p.fg, bg = p.bg_dim },
    BlinkCmpDocBorder = { fg = p.rose, bg = p.bg_dim },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_dim },
    BlinkCmpSignatureHelpActiveParameter = { fg = p.pink, bold = true },
    BlinkCmpGhostText = { fg = p.faint, italic = true },

    -- which-key ------------------------------------------------------------
    WhichKey = { fg = p.pink },
    WhichKeyGroup = { fg = p.type },
    WhichKeyDesc = { fg = p.fg },
    WhichKeySeparator = { fg = p.pink_soft },
    WhichKeyValue = { fg = p.purple2 },
    WhichKeyFloat = { bg = p.bg_dim },
    WhichKeyBorder = { fg = p.rose, bg = p.bg_dim },
    WhichKeyTitle = { fg = p.pink, bg = p.bg_dim, bold = true },

    -- indent-blankline -----------------------------------------------------
    IblIndent = { fg = "#f6dde8" },
    IblScope = { fg = p.rose },

    -- gitsigns / trouble / oil --------------------------------------------
    TroubleNormal = { fg = p.fg, bg = p.bg_dim },
    TroubleText = { fg = p.fg },
    TroubleCount = { fg = p.pink, bg = p.bg_pink, bold = true },
    OilDir = { fg = p.type, bold = true },
    OilCreate = { fg = p.add },
    OilDelete = { fg = p.delete },
    OilMove = { fg = p.change },
    OilCopy = { fg = p.info },

    -- todo-comments (links its keywords to these) --------------------------
    TodoBgTODO = { fg = p.bg, bg = p.info, bold = true },
    TodoFgTODO = { fg = p.info },
    TodoBgFIX = { fg = p.bg, bg = p.error, bold = true },
    TodoFgFIX = { fg = p.error },
    TodoBgNOTE = { fg = p.bg, bg = p.add, bold = true },
    TodoFgNOTE = { fg = p.add },

    -- nyan-cat statusline component ---------------------------------------
    CuteNyanBar = { fg = p.pink, bg = p.bg_alt },
    CuteNyanCat = { fg = p.purple2, bg = p.bg_alt, bold = true },

    -- DAP ------------------------------------------------------------------
    DapBreakpoint = { fg = p.delete },
    DapBreakpointCondition = { fg = p.change },
    DapLogPoint = { fg = p.info },
    DapStopped = { fg = p.add },
    DapStoppedLine = { bg = p.peach },
  }

  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end

  -- Terminal colors (pink-leaning ANSI from the theme).
  vim.g.terminal_color_0 = p.fg
  vim.g.terminal_color_8 = p.purple2
  vim.g.terminal_color_1 = p.delete
  vim.g.terminal_color_9 = p.error
  vim.g.terminal_color_2 = p.add
  vim.g.terminal_color_10 = p.number
  vim.g.terminal_color_3 = p.change
  vim.g.terminal_color_11 = p.warn
  vim.g.terminal_color_4 = p.type
  vim.g.terminal_color_12 = p.info
  vim.g.terminal_color_5 = p.pink
  vim.g.terminal_color_13 = p.rose
  vim.g.terminal_color_6 = p.purple2
  vim.g.terminal_color_14 = p.purple
  vim.g.terminal_color_7 = p.fg
  vim.g.terminal_color_15 = p.purple_dk
end

return M
