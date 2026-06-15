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

    -- 4b. marksman — Markdown LSP: completion for links, headings, references and
    --     wiki-links. Only if installed (`brew install marksman` or the release
    --     binary). Completion rides blink.cmp (capabilities set above); hover /
    --     goto are wired by the LspAttach maps below (K, gd) like any server.
    if vim.fn.executable("marksman") == 1 then
      vim.lsp.config("marksman", {
        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".marksman.toml", ".git" },
      })
      vim.lsp.enable("marksman")
    end

    -- 4c. Auto-hover: after the cursor rests on a symbol for ~3s, show its
    --     definition in a small popup docked to a corner *away* from the cursor,
    --     so it never covers the code you're reading. <leader>ch shows it on
    --     demand; <leader>cH toggles the idle behavior. (K stays the native,
    --     cursor-adjacent, focusable hover.) A libuv timer drives the 3s delay so
    --     the global `updatetime` (250ms, shared with other features) is untouched.
    local uv = vim.uv or vim.loop
    local hover = { timer = uv.new_timer(), enabled = true, delay = 3000 }

    local function show_hover_docked()
      -- Skip when already inside a floating window (e.g. the popup itself).
      if vim.api.nvim_win_get_config(0).relative ~= "" then
        return
      end
      local buf = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/hover" })
      if #clients == 0 then
        return
      end
      local client = clients[1]
      local win = vim.api.nvim_get_current_win()
      local win_h = vim.api.nvim_win_get_height(win)
      local cur_row = vim.fn.winline() -- cursor's screen row within the window
      local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
      client:request("textDocument/hover", params, function(err, result)
        if err or not result or not result.contents then
          return
        end
        local conv = vim.lsp.util.convert_input_to_markdown_lines
        local lines
        if conv then
          lines = conv(result.contents)
        else -- defensive fallback if the util is unavailable
          local c = result.contents
          lines = vim.split(type(c) == "table" and (c.value or "") or tostring(c), "\n", { trimempty = true })
        end
        if not lines or vim.tbl_isempty(lines) then
          return
        end
        local ok, _fbuf, fwin = pcall(vim.lsp.util.open_floating_preview, lines, "markdown", {
          border = "rounded",
          max_width = 72,
          max_height = 20,
          focusable = true,
          focus = false,
          close_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinScrolled" },
        })
        -- Re-dock the float to the corner opposite the cursor's half of the window
        -- (cursor up top → popup bottom, and vice-versa), flush right — keeping it
        -- clear of the line under the cursor.
        if ok and fwin and vim.api.nvim_win_is_valid(fwin) then
          local cfg = vim.api.nvim_win_get_config(fwin)
          local w, h = cfg.width or 40, cfg.height or 10
          local dock_bottom = cur_row <= math.floor(win_h / 2)
          local row = dock_bottom and (vim.o.lines - h - 4) or 1
          pcall(vim.api.nvim_win_set_config, fwin, {
            relative = "editor",
            row = math.max(0, row),
            col = math.max(0, vim.o.columns - w - 2),
          })
        end
      end, buf)
    end

    -- Drive the 3s idle delay with a libuv timer re-armed on every cursor move.
    local function arm_hover()
      hover.timer:stop()
      if not hover.enabled then
        return
      end
      hover.timer:start(hover.delay, 0, function()
        vim.schedule(function()
          if vim.fn.mode() == "n" then
            show_hover_docked()
          end
        end)
      end)
    end

    local hover_group = vim.api.nvim_create_augroup("cute_auto_hover", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
      group = hover_group,
      desc = "Arm the 3s idle auto-hover timer",
      callback = arm_hover,
    })
    vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
      group = hover_group,
      desc = "Cancel the idle auto-hover timer",
      callback = function()
        hover.timer:stop()
      end,
    })

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
        map("n", "<leader>ch", show_hover_docked, "Hover definition (docked popup)")
        map("n", "<leader>cH", function()
          hover.enabled = not hover.enabled
          if not hover.enabled then
            hover.timer:stop()
          end
          vim.notify("Auto-hover " .. (hover.enabled and "on" or "off"), vim.log.levels.INFO)
        end, "Toggle auto-hover (3s)")
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
