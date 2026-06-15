-- Syntax highlighting + indentation via tree-sitter.
-- Uses the `master` branch: the `main` rewrite requires Neovim 0.12 (nightly);
-- `master` is the maintained, backward-compatible branch for 0.10/0.11.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- REQUIRED: default will flip to `main` in the future
  lazy = false, -- this plugin does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      -- Python + parsers useful for AI/data work and editing this config.
      ensure_installed = {
        "python",
        "toml",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
        "bash",
        "lua",
        "vimdoc",
        "regex",
        "requirements", -- pip requirements.txt
        "htmldjango",
        "query", -- treesitter .scm query files
      },
      sync_install = false,
      auto_install = true, -- needs the tree-sitter CLI in PATH (you have it)
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
        -- Python TS indent occasionally misbehaves; uncomment if it bothers you:
        -- disable = { "python" },
      },
    })
  end,
}
