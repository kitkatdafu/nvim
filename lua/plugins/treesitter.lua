-- Syntax highlighting + indentation via tree-sitter.
-- Uses the `main` branch: the legacy `master` branch tops out below Neovim 0.12
-- (its injection predicates call the pre-0.11 single-node match API and crash on
-- 0.12). `main` is the rewrite that targets current Neovim. Its model is different:
--   • parsers are installed with `require("nvim-treesitter").install{...}` (no
--     `ensure_installed`; the call is a no-op when already installed) into
--     `stdpath("data")/site`, NOT the old `<plugin>/parser/` dir;
--   • highlighting is NOT auto-enabled — Neovim owns it; we start it per buffer
--     with `vim.treesitter.start()` in a FileType autocmd;
--   • injections (markdown_inline, regex, latex math) are automatic — no setup;
--   • indentation is provided here but experimental, enabled via `indentexpr`.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", -- the 0.12-compatible rewrite (was "master")
  lazy = false, -- highlighting must be available before files open
  build = ":TSUpdate",
  config = function()
    -- Python + parsers useful for AI/data work and editing this config.
    -- NOTE installing through nvim-treesitter is what puts the *queries* on the
    -- runtimepath (Neovim itself bundles queries for only c/lua/markdown/query/
    -- vim/vimdoc), so `cpp` here is what makes C++ highlighting work at all.
    local parsers = {
      "python",
      "toml",
      "json",
      "yaml",
      "markdown",
      "markdown_inline",
      "bash",
      "lua",
      "vim", -- Vimscript (.vim plugin files); matches main's bundled vim query
      "vimdoc",
      "regex",
      "requirements", -- pip requirements.txt
      "htmldjango",
      "query", -- treesitter .scm query files
      -- C / C++
      "c",
      "cpp",
      "cmake",
      "make",
      "doxygen", -- injected into /** … */ comments by the c/cpp queries
      "printf", -- injected into printf/scanf format strings
    }
    -- `latex` (math inside markdown) isn't shipped precompiled — the tree-sitter
    -- CLI must generate it. Request it only when that CLI is on PATH, else the
    -- install errors where it's absent. render-markdown needs this parser to
    -- render $…$ / $$…$$; without it, math falls back to raw source.
    if vim.fn.executable("tree-sitter") == 1 then
      table.insert(parsers, "latex")
    end

    -- Install (or update) the parsers. No-op for ones already present; async, so
    -- it never blocks startup. `:TSUpdate` (the build step) refreshes them later.
    require("nvim-treesitter").install(parsers)

    -- C/C++ use Neovim's built-in 'cindent' instead (see lua/config/cc.lua):
    -- nvim-treesitter's C/C++ indent is experimental, and a non-empty
    -- 'indentexpr' overrules 'cindent'.
    local native_indent = { c = true, cpp = true, cuda = true, objc = true, objcpp = true }

    -- Enable highlighting + (experimental) indentation for every buffer whose
    -- filetype resolves to an installed parser. `vim.treesitter.start` derives
    -- the language from the filetype and errors when no parser exists, so the
    -- pcall keeps unsupported filetypes silent. This replaces the old
    -- `highlight.enable` / `indent.enable` options from the master branch.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("cute_treesitter", { clear = true }),
      callback = function(ev)
        if not pcall(vim.treesitter.start, ev.buf) then
          return
        end
        if native_indent[ev.match] then
          return
        end
        -- Experimental TS indent (parity with the old `indent.enable = true`),
        -- but ONLY where an `indents` query actually exists: setting indentexpr
        -- without one makes it return 0 for every line, so `=`/`gg=G` silently
        -- flattens the whole buffer to column 0.
        local lang = vim.treesitter.language.get_lang(ev.match)
        if lang and vim.treesitter.query.get(lang, "indents") then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
