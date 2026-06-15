# CLAUDE.md

Guidance for AI assistants working in this Neovim configuration.

## What this is

A hand-rolled (not a distro) Neovim 0.12+ config for **Python / AI-ML**, managed by
**lazy.nvim**, designed to be **uv-native**, using **GitHub Copilot** for AI, and
themed with a bespoke **`cute`** pink-light colorscheme + a Nyan-cat statusline.

## Architecture

```
init.lua                    leaders → host → require config/* → lazy bootstrap → colorscheme "cute"
lua/config/options.lua      vim.opt + vim.diagnostic.config
lua/config/keymaps.lua      global, non-plugin maps
lua/config/autocmds.lua     yank-hl, trim-whitespace, last-loc, q-to-close
lua/config/python.lua       *** uv integration: venv resolver + run/REPL keymaps ***
lua/cute/init.lua           colorscheme: palette + load() (sets all highlights)
lua/cute/lualine.lua        lualine theme table (reads cute.palette)
lua/cute/nyan.lua           width-capped animated nyan statusline component
colors/cute.lua             `:colorscheme cute` → require("cute").load()
lua/plugins/*.lua           one concern per file, auto-imported by lazy
```

Plugin files: `treesitter`, `lsp`, `completion` (blink), `conform` (format),
`copilot` (engine + chat), `datascience` (molten/jupyter), `dap`, `neotest`,
`telescope`, `oil`, `lualine`, `gitsigns`, `which-key`, `editor`, `trouble`,
`markdown` (render-markdown + vim-table-mode).

## Conventions — follow these

- **Native LSP only.** Use `vim.lsp.config(name, {...})` + `vim.lsp.enable(name)`
  (Neovim 0.11). Do **not** use the deprecated `require("lspconfig").x.setup{}`.
- **One interpreter, via `config.python`.** Anything Python-related (LSP, dap,
  neotest, kernels, run/REPL) must resolve the interpreter through
  `require("config.python").venv_python()` / `.python()`. Never hardcode `python3`.
- **Tool responsibilities are split:** pyrefly = types + hover; ruff = lint +
  code actions + organize imports; conform = formatting. ruff's hover is disabled
  on attach (see `lua/plugins/lsp.lua`) — keep it that way.
- **Diagnostics API:** use `vim.diagnostic.jump({count=…})`, not the deprecated
  `goto_next/goto_prev`. Use `vim.hl.on_yank`, not `vim.highlight.on_yank`.
- **Leader namespaces:** `f`=find, `c`=code/lsp, `r`=run/uv, `t`=test, `d`=debug,
  `a`=AI, `h`=git, `x`=diagnostics, `w`=window/splits, `m`=markdown,
  `<Tab>`=tabs. `<localleader>` (`\`) = Jupyter/molten.
  Register new groups in `lua/plugins/which-key.lua`.
- **Style:** `.stylua.toml` governs Lua formatting (2-space indent). Match it.

## Pinned facts (don't "fix" these)

- **treesitter is on `branch = "main"`** (the 0.12-compatible rewrite). The old
  `master` branch crashes on Neovim 0.12 (its injection predicates use the pre-0.11
  single-node match API). `main` has a different model: parsers install via
  `require("nvim-treesitter").install{...}` into `stdpath("data")/site` (no
  `ensure_installed`/`auto_install`), and highlighting is started per-buffer with
  `vim.treesitter.start()` in a FileType autocmd (see `lua/plugins/treesitter.lua`).
  Every parser is built by the `tree-sitter` CLI — it is **required**, not optional.
- **blink.cmp is pinned `version = "1.*"`** — v2 is unreleased; keep v1.
- **No `ANTHROPIC_API_KEY`** — AI is GitHub Copilot via `:Copilot auth`. Don't add
  Claude/CodeCompanion unless asked.
- **Copilot ghost-text is intentionally OFF** — Copilot shows in the blink menu via
  `fang2hou/blink-copilot`. Don't enable both (duplicate suggestions).
- **CopilotChat has no `build` step** — `make tiktoken` needs luarocks (absent); it's
  optional. Don't add it back without confirming luarocks is installed.
- **Theme is light by design.** `lua/cute/` is a faithful port of webfreak's
  "Cute Pink Light" VS Code theme (white bg + pink chrome + Light+ syntax).
- **nyan statusline** uses `lua/cute/nyan.lua` (capped width); the real
  `nyan-modoki.vim` is installed but its full-width `g:NyanModoki()` is not used in
  lualine on purpose (it sizes to winwidth/2).
- **`~` toggles a bottom-split terminal** (`lua/config/keymaps.lua`), intentionally
  overriding the built-in case-toggle — `g~{motion}` still toggles case. The shell
  persists across toggles and a `TermClose` autocmd respawns it after you `exit`.
- **Auto-hover uses a libuv timer, not `updatetime`** (`lua/plugins/lsp.lua`, augroup
  `cute_auto_hover`): after the cursor idles 3s on a symbol it shows the hover in a
  popup docked to the corner *opposite* the cursor, so it never covers the code.
  Keep the timer — the global `updatetime` is 250ms, shared with other features.
  `<leader>ch` shows it on demand, `<leader>cH` toggles it; `K` stays native hover.
- **Cheatsheet floats lower-right** (`lua/cute/cheatsheet.lua`), not centered — so it
  doesn't cover the editing area. Keep the bottom-right docking math.

## Validate after changes

```sh
# Syntax + cute-module load check (fast, no plugin install):
nvim --headless -l /tmp/nvim_check.lua    # see the script in git history / recreate

# Or inline: parse every lua file + load the theme
nvim --headless +"lua for _,f in ipairs(vim.fn.globpath(vim.fn.stdpath('config'),'**/*.lua',false,true)) do assert(loadfile(f)) end; require('cute').load(); print('OK')" +q

# Full plugin install / spec validation:
nvim --headless "+Lazy! sync" +qa

# Startup smoke test (theme applied, statusline renders):
nvim --headless +"sleep 2" +"lua print(vim.g.colors_name)" +qa!
```

## Known external dependencies (user-installed, not in repo)

- `pyrefly`, `ruff` on PATH (`uv tool install …`)
- `marksman` (Markdown LSP) — optional; `brew install marksman` or release binary
- **`tree-sitter` CLI on PATH — REQUIRED.** The `main` branch builds every parser
  with it. Homebrew's `tree-sitter` formula is library-only (no CLI binary), so the
  CLI here is the prebuilt release binary at `~/.local/bin/tree-sitter`. Without it,
  no parser installs and `:TSUpdate` fails.
- render-markdown LaTeX math (optional) needs BOTH the `latex` treesitter parser
  (installed by the `tree-sitter` CLI above) AND a converter: `utftex`, or
  `latex2text` from `uv tool install pylatexenc`. Missing the converter, math just
  shows as raw `$…$` source.
- molten host venv at `~/.virtualenvs/neovim` with `pynvim`+`jupyter_client`
  (until present, `:UpdateRemotePlugins` warns — expected, not a bug)
- `debugpy` / `pytest` / `ipykernel` in each project venv (`uv add --dev …`)
- Neovim ≥ 0.12 (nvim-treesitter `main` branch), a Nerd Font, ImageMagick, a
  graphics terminal

See `README.md` for the full setup walkthrough.
