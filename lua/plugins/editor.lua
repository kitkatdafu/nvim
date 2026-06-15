-- Editing quality-of-life: autopairs, indent guides, TODO comments, mini.*.
return {
  -- Auto-close brackets/quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Indent guides (v3 requires main = "ibl")
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      indent = { char = "│" },
      scope = { enabled = true },
    },
  },

  -- Highlight + navigate TODO/FIXME/NOTE comments
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo comment" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Todo (Telescope)" },
    },
  },

  -- mini.ai: smarter a/i text objects (aq/iq quotes, af/if functions, aa/ia args)
  { "nvim-mini/mini.ai", event = "VeryLazy", opts = {} },
  -- mini.surround: gsa add / gsd delete / gsr replace
  { "nvim-mini/mini.surround", event = "VeryLazy", opts = {} },
}
