-- ============================================================================
-- LSP — Neovim 0.11 native (vim.lsp.config / vim.lsp.enable).
--   • pyrefly  → type checking + hover            (Meta's Rust type checker)
--   • ruff     → diagnostics + code actions + organize imports (Astral)
--   formatting is owned by conform.nvim (see conform.lua); hover by pyrefly.
--
-- uv: both servers auto-detect the project's `.venv` at the uv project root.
-- Launch nvim from inside the project (so `.venv` is found) and run
-- `:LspRestart` after creating/switching the venv (e.g. after `uv sync`).
-- ============================================================================
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "saghen/blink.cmp" },
  config = function()
    -- 1. Advertise blink.cmp's completion capabilities to every server.
    vim.lsp.config("*", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
    })

    -- 2. ruff — linter + code actions + organize imports. No hover (pyrefly owns
    --    it), no formatting from the LSP (conform runs `ruff format`).
    vim.lsp.config("ruff", {
      cmd = { "ruff", "server" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", "uv.lock", ".git" },
      init_options = {
        settings = {
          fixAll = true,
          organizeImports = true,
          lint = { enable = true },
        },
      },
    })

    -- 3. pyrefly — type checking + hover. Auto-detects the uv `.venv`.
    vim.lsp.config("pyrefly", {
      cmd = { "pyrefly", "lsp" },
      filetypes = { "python" },
      root_markers = {
        "pyrefly.toml",
        "pyproject.toml",
        "uv.lock",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        ".git",
      },
    })

    vim.lsp.enable({ "pyrefly", "ruff" })

    -- 4. lua_ls for editing this config — only if it's installed.
    if vim.fn.executable("lua-language-server") == 1 then
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable("lua_ls")
    end

    -- 5. On attach: split ruff/pyrefly responsibilities + buffer-local keymaps.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("cute_lsp_attach", { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "ruff" then
          -- pyrefly provides hover/type info; silence ruff's so they don't fight.
          client.server_capabilities.hoverProvider = false
        end

        local buf = args.buf
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end
        -- Navigation (gr*, K are nvim 0.11 defaults; these add the rest).
        map("n", "gd", vim.lsp.buf.definition, "Goto definition")
        map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
        map("n", "gy", vim.lsp.buf.type_definition, "Goto type definition")
        map("n", "K", vim.lsp.buf.hover, "Hover (pyrefly)")
        -- Code actions live under <leader>c.
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
        map("n", "<leader>co", function()
          vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" }, diagnostics = {} },
            apply = true,
          })
        end, "Organize imports (ruff)")
        map("n", "<leader>ci", function()
          local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
          vim.lsp.inlay_hint.enable(not enabled, { bufnr = buf })
        end, "Toggle inlay hints")
        -- Diagnostic motions (0.11 jump API; goto_next/prev are deprecated).
        map("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, "Next diagnostic")
        map("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, "Prev diagnostic")
      end,
    })
  end,
}
