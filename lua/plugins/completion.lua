-- Completion — blink.cmp (v1, prebuilt Rust fuzzy matcher) with GitHub Copilot
-- surfaced as a source via fang2hou/blink-copilot. Copilot ghost-text is OFF
-- (see copilot.lua); suggestions appear in the menu instead, ranked on top.
return {
  "saghen/blink.cmp",
  version = "1.*", -- pin a release => lazy auto-downloads the prebuilt binary
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "rafamadriz/friendly-snippets",
    { "L3MON4D3/LuaSnip", version = "v2.*" },
    "fang2hou/blink-copilot", -- Copilot source for blink (needs copilot.lua)
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' = C-y accept, C-space menu/docs, C-n/C-p select, Tab snippet jump.
    keymap = { preset = "default" },
    appearance = {
      nerd_font_variant = "mono",
      kind_icons = { Copilot = "" },
    },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 250 },
      ghost_text = { enabled = false }, -- Copilot's own ghost text is off too
      menu = { border = "rounded" },
    },
    sources = {
      -- Copilot first so it ranks above LSP/snippet/path/buffer.
      default = { "copilot", "lsp", "path", "snippets", "buffer" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
          opts = {
            max_completions = 3,
            kind_name = "Copilot",
            kind_icon = " ",
          },
        },
      },
    },
    snippets = { preset = "luasnip" },
    signature = { enabled = true }, -- opt-in in v1; <C-k> toggles it
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
