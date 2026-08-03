-- Formatting — conform.nvim driving ruff (Python) and clang-format (C/C++),
-- format-on-save. Order matters for Python: organize imports first, then format.
-- ruff must be on PATH; clang-format is found via config.cc (the Xcode Command
-- Line Tools ship it, but not on $PATH).
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "never" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer/range",
    },
    {
      "<leader>cF",
      function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("format-on-save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
      end,
      desc = "Toggle format-on-save",
    },
  },
  opts = function()
    local cc = require("config.cc")

    -- A function-valued formatters_by_ft entry returning {} is the *only* way to
    -- stay quiet when a formatter is missing: conform checks executability
    -- before `condition`, so it would otherwise warn "Formatters unavailable for
    -- cpp file" on every save. (An empty list skips that branch entirely.)
    local function clang_format_if_present()
      return cc.clang_format() and { "clang-format" } or {}
    end

    -- Respect a project's own .clang-format; only when there isn't one, fall
    -- back to a style that matches this config's editor defaults instead of
    -- LLVM's 2-space/80-column one. (An inline -style= *overrides* a project
    -- file, so it must only be passed when no such file exists.)
    local function style_arg(ctx)
      local found = vim.fs.find(".clang-format", { path = ctx.dirname, upward = true, type = "file" })[1]
      if found then
        return "-style=file"
      end
      -- IndentCaseLabels matches the `:1s,=1s` cinoptions, so typing and
      -- formatting agree about `case X:` instead of fighting on every save.
      return ("-style={BasedOnStyle: LLVM, IndentWidth: %d, ColumnLimit: %d, IndentCaseLabels: true}"):format(
        cc.settings.indent,
        cc.settings.column
      )
    end

    return {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        lua = { "stylua" }, -- if stylua is installed; harmless otherwise
        c = clang_format_if_present,
        cpp = clang_format_if_present,
        cuda = clang_format_if_present,
        objc = clang_format_if_present,
        objcpp = clang_format_if_present,
      },
      formatters = {
        ["clang-format"] = {
          -- Called twice per format (availability check + argv build), so the
          -- resolver behind cc.clang_format() memoizes its xcrun lookup.
          command = function()
            return cc.clang_format() or "clang-format"
          end,
          args = function(_, ctx)
            return { "--assume-filename", "$FILENAME", style_arg(ctx) }
          end,
          -- range_args takes precedence over args whenever a range is set, so
          -- visual-mode formatting would silently lose the style above.
          range_args = function(_, ctx)
            local from, to = require("conform.util").get_offsets_from_range(ctx.buf, ctx.range)
            return {
              "--assume-filename",
              "$FILENAME",
              style_arg(ctx),
              "--offset",
              tostring(from),
              "--length",
              tostring(to - from),
            }
          end,
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "never" }
      end,
    }
  end,
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
