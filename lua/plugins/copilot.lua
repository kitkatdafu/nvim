-- ============================================================================
-- GitHub Copilot — authenticate with `:Copilot auth` (browser, no API key).
--   • copilot.lua  → the Copilot engine. Inline ghost-text + panel are OFF;
--     completions surface in the blink.cmp menu via blink-copilot instead.
--   • CopilotChat  → chat buffer + visual-selection actions; `:CopilotChatModels`
--     picks any model on your Copilot plan (GPT, Claude, Gemini, …).
-- ============================================================================
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false }, -- menu shows Copilot, not ghost text
      panel = { enabled = false },
      filetypes = {
        ["*"] = true,
        markdown = true,
        help = false,
        gitcommit = false,
        gitrebase = false,
        TelescopePrompt = false,
      },
      -- copilot_node_command = "node", -- set if your default node is < v22
    },
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = { "CopilotChat", "CopilotChatToggle", "CopilotChatModels", "CopilotChatPrompts" },
    dependencies = {
      "zbirenbaum/copilot.lua",
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    -- `make tiktoken` (accurate token counts) needs luarocks + a toolchain, which
    -- isn't installed here, so it's omitted. Chat works fine without it. To enable:
    -- install luarocks, then add  build = "make tiktoken".
    opts = {
      model = "gpt-4o", -- change via :CopilotChatModels (Claude/Gemini/… on your plan)
      auto_insert_mode = true,
      window = { layout = "vertical", width = 0.4 },
    },
    keys = {
      { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "Copilot Chat" },
      { "<leader>ax", "<cmd>CopilotChatReset<cr>", desc = "Reset chat" },
      { "<leader>am", "<cmd>CopilotChatModels<cr>", desc = "Pick model" },
      { "<leader>ap", function() require("CopilotChat").select_prompt() end, mode = { "n", "v" }, desc = "Prompt actions" },
      { "<leader>ae", ":CopilotChat /Explain<cr>", mode = "v", desc = "Explain selection" },
      { "<leader>af", ":CopilotChat /Fix<cr>", mode = "v", desc = "Fix selection" },
      { "<leader>at", ":CopilotChat /Tests<cr>", mode = "v", desc = "Generate tests" },
      { "<leader>ar", ":CopilotChat /Review<cr>", mode = "v", desc = "Review selection" },
      {
        "<leader>aq",
        function()
          local input = vim.fn.input("Quick Chat: ")
          if input ~= "" then
            require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
          end
        end,
        desc = "Quick chat (buffer)",
      },
    },
  },
}
