# CLAUDE.md

Guidance for AI assistants working in this Neovim configuration.

## What this is

A hand-rolled (not a distro) Neovim 0.12+ config for **Python / AI-ML** and
**C/C++**, managed by **lazy.nvim**, designed to be **uv-native**, using **GitHub
Copilot** for AI, and themed with a bespoke **`cute`** pink-light colorscheme + a
Nyan-cat statusline.

## Architecture

```
init.lua                    leaders → host → require config/* → lazy bootstrap → colorscheme "cute"
lua/config/options.lua      vim.opt + vim.diagnostic.config
lua/config/keymaps.lua      global, non-plugin maps
lua/config/autocmds.lua     yank-hl, trim-whitespace, last-loc, q-to-close
lua/config/python.lua       *** uv integration: venv resolver + run/REPL keymaps ***
lua/config/cc.lua           *** C/C++ integration: tool discovery (xcrun), project
                            detection, quickfix errorformat, the run terminal,
                            single-file + CMake + Makefile builds, ctest, debug,
                            .h filetype sniffing, cindent, <leader>r keymaps ***
lua/cute/init.lua           colorscheme: palette + load() (sets all highlights)
lua/cute/lualine.lua        lualine theme table (reads cute.palette)
lua/cute/nyan.lua           width-capped animated nyan statusline component
colors/cute.lua             `:colorscheme cute` → require("cute").load()
lua/plugins/*.lua           one concern per file, auto-imported by lazy
```

Plugin files: `treesitter`, `lsp`, `completion` (blink), `conform` (format),
`copilot` (engine + chat), `datascience` (molten/jupyter), `dap`, `neotest`,
`telescope`, `oil`, `lualine`, `gitsigns`, `which-key`, `editor`, `trouble`,
`markdown` (render-markdown + vim-table-mode), `snacks` (image-based LaTeX math).

## Conventions — follow these

- **Native LSP only.** Use `vim.lsp.config(name, {...})` + `vim.lsp.enable(name)`
  (Neovim 0.11). Do **not** use the deprecated `require("lspconfig").x.setup{}`.
- **One interpreter, via `config.python`.** Anything Python-related (LSP, dap,
  neotest, kernels, run/REPL) must resolve the interpreter through
  `require("config.python").venv_python()` / `.python()`. Never hardcode `python3`.
- **One C/C++ toolchain, via `config.cc`.** clangd's argv, clang-format's path and
  the lldb-dap path all come from `require("config.cc")` (`.clangd_cmd()`,
  `.clang_format()`, `.lldb_dap()`). Never hardcode a compiler or a
  `/Library/Developer/...` path — `M.tool()` resolves $PATH then `xcrun -f` and
  memoizes. Build/run/debug logic belongs in `cc.lua`, not in a plugin spec.
- **Tool responsibilities are split:** pyrefly = types + hover; ruff = lint +
  code actions + organize imports; conform = formatting. ruff's hover is disabled
  on attach (see `lua/plugins/lsp.lua`) — keep it that way.
- **Diagnostics API:** use `vim.diagnostic.jump({count=…})`, not the deprecated
  `goto_next/goto_prev`. Use `vim.hl.on_yank`, not `vim.highlight.on_yank`.
- **Leader namespaces:** `f`=find, `c`=code/lsp, `r`=run/build, `t`=test, `d`=debug,
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
- **Math is image-based, not text** (`lua/plugins/snacks.lua`). snacks.image compiles
  each `$…$` / `$$…$$` to a PNG (`pdflatex` → ImageMagick) and shows it inline via the
  kitty graphics protocol. It finds math through the `latex` tree injected into markdown
  (`queries/latex/images.scm` runs on the injected tree), so **no custom query is
  needed**. Because of this, render-markdown's `latex` is intentionally OFF and
  image.nvim's `integrations.markdown` is OFF (image.nvim stays only as molten's
  provider) — exactly one library owns markdown math/images. snacks is
  `lazy=false, priority=1000` (per its own health check). To switch to text math: flip
  `latex.enabled=true` in `markdown.lua` and `image.math.enabled=false` in `snacks.lua`.

## Pinned facts — C/C++ (all verified on this machine; don't "fix" them)

- **Zero new plugins.** clangd, clang-format and lldb-dap all ship with the Xcode
  Command Line Tools. `clang-format` and `lldb-dap` are **not on `$PATH`**; they are
  found with `xcrun -f` (see `M.tool()`). Don't add clangd_extensions,
  cmake-tools.nvim, or a DAP installer.
- **Two clangd server configs on purpose** (`clangd` for cpp/objcpp/cuda,
  `clangd_c` for c/objc). `init_options.fallbackFlags = {"-std=c++23"}` is what makes
  a *bare* .cpp file work (Apple clang defaults to gnu++14), but clangd hard-errors
  with "invalid argument '-std=c++23' not allowed with 'C'" if that reaches a .c
  file, and init_options are per-server. Don't merge them back into one.
- **Never set `on_attach` in `vim.lsp.config("clangd", …)`.** nvim-lspconfig ships
  `lsp/clangd.lua`, and `vim.lsp.config` merges with `tbl_deep_extend("force", …)`,
  which *overwrites* function values — a local `on_attach` silently destroys
  `:LspClangdSwitchSourceHeader` and `:LspClangdShowSymbolInfo`. Keymaps go in the
  `LspAttach` autocmd. Likewise don't set `root_markers`: lspconfig's list already
  covers `.clangd`/`compile_flags.txt`/`compile_commands.json`/`configure.ac`/`.git`,
  and list keys are replaced wholesale, not merged.
- **No `-isysroot` anywhere.** Apple clangd injects the SDK path itself; a
  hardcoded `xcrun --show-sdk-path` value goes stale after an Xcode update and then
  *nothing* resolves (there is no `/usr/include` on macOS).
- **The custom `errorformat` is load-bearing** (`cc.M.errorformat`). Neovim's default
  types *nothing* for clang (" error: " is swallowed into `%m`) and turns every
  include-chain line into a junk entry, because efm patterns are END-ANCHORED and the
  built-in `In file included from %f:%l` never matches clang's trailing-colon
  `foo.cpp:1:`. Compilers must also be called with `-fno-color-diagnostics` (an ANSI
  escape lands *inside* `%f`, making the entry unopenable) and
  `-fdiagnostics-absolute-paths`. The `": "` in `%-Gmake: %.%#` is required — a bare
  `%-Gmake%.%#` would swallow real errors from `make_helpers.cpp`.
- **`-fno-sanitize-recover=undefined` is not optional** with `<leader>rz`: UBSan
  otherwise prints the diagnostic, keeps running and exits 0. Related: a signal death
  reaches `vim.system` as `code = 0, signal = 6`, and `sh -c '<bin>'` does *not* fix
  it (sh exec-optimizes the child) — hence `launch_cmd()` appends `; exit $?`.
  Never put `detect_leaks=1` in ASAN_OPTIONS; it is unsupported on macOS arm64 and
  aborts even correct programs.
- **`runInTerminal = false` for lldb-dap, permanently.** The launcher process *is*
  the Apple-signed `lldb-dap`, which macOS won't let the adapter attach to. Stdout
  still arrives in the dap REPL; the cost is no interactive stdin. There is also no
  `--port` flag on the CLT build, so the adapter must be `type = "executable"`.
  Breakpoints need the sibling `.dSYM` a one-step `clang++ -g` produces — macOS keeps
  no DWARF in the executable.
- **CMake targets come from the File API**, not from parsing output: write an empty
  `.cmake/api/v1/query/client-nvim/codemodel-v2` *before* generating, then walk
  index → codemodel → per-target JSON (the codemodel stubs carry no `type`).
  `artifacts[].path` is relative to the **top-level** build dir, never to
  `target.paths.build`. "Configured" means `CMakeCache.txt` **and** a
  `Makefile`/`build.ninja` — a failed generate leaves the cache behind.
- **C/C++ indent is `cindent`, not treesitter.** A non-empty `'indentexpr'` overrules
  `'cindent'`, so `treesitter.lua` skips those filetypes and `cc.lua` sets the tuned
  `cinoptions`. That autocmd also now only sets `indentexpr` when an `indents` query
  really exists — without one, `indentexpr` returns 0 for every line and `gg=G`
  flattens the buffer (which is what `.c` files used to do).
- **`.h` sniffing is deliberate.** Neovim 0.12 resolves `.h` to **cpp** by default;
  `cc.lua`'s `vim.filetype.add` reads the first 200 lines so C headers get `c`. That
  entry *replaces* the built-in, so it must always return a filetype (returning nil
  falls through to content detection and yields `conf`) — hence the explicit
  delegation to `vim.filetype.detect.header` for empty buffers.
- **conform's `formatters_by_ft` entries for C/C++ are functions** returning `{}` when
  clang-format is missing. That is the only fully silent path: conform checks
  executability before `condition`, so it would otherwise warn on every save. The
  `range_args` override is also required — it takes precedence over `args`, so
  visual-mode formatting would otherwise lose the style flags.
- **Project queries resolve from the *source* buffer**, not the focused window
  (`source_buf()` / `last_source`): running a program leaves the cursor in the run
  terminal, and the quickfix window isn't a file either.

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

C/C++ changes are worth an end-to-end check, since most of `cc.lua` is async:

```sh
# 1. a lone file: write /tmp/x.cpp, then in nvim on it
#    <leader>rr  -> compiles + runs in the bottom split (winbar shows "exit 0 · Nms")
#    break it    -> <leader>rr fills the quickfix list, cursor on the first error
#    <leader>rz  -> asan+ubsan; a signed-overflow program must NOT report exit 0
# 2. a project: :CcInit then <leader>rg, <leader>rr, <leader>tt
# 3. clangd on a bare file (no compile DB): std::format / std::span must resolve
#    with no diagnostics — that's init_options.fallbackFlags doing its job.
#
# `nvim -l script.lua` does NOT load init.lua (loadplugins=false, no filetype
# detection): use `nvim --headless "+luafile script.lua" +qa` to test integration,
# and `nvim --headless --clean -l script.lua` (+ rtp prepend) to test cc.lua alone.
```

## Known external dependencies (user-installed, not in repo)

- `pyrefly`, `ruff` on PATH (`uv tool install …`)
- **C/C++: nothing beyond the Xcode Command Line Tools** (`xcode-select --install`)
  — clangd, clang-format and lldb-dap all come from there. `cmake` (brew) is needed
  only for CMake projects and `ctest`; `ninja` is used automatically if present, else
  CMake falls back to "Unix Makefiles". There is no `gdb` on macOS arm64 and no
  standalone `clang-tidy` (clangd runs it in-process). `cmake-language-server` is
  optional (`uv tool install cmake-language-server`).
- `marksman` (Markdown LSP) — optional; `brew install marksman` or release binary
- **`tree-sitter` CLI on PATH — REQUIRED** (≥ 0.26.1). The `main` branch builds every
  parser with it. Homebrew's plain `tree-sitter` formula is library-only (no CLI), so
  install the CLI via `brew install tree-sitter-cli` **or** the prebuilt release binary
  at `~/.local/bin/tree-sitter` (currently v0.26.11). Without it, no parser installs
  and `:TSUpdate` fails.
- **LaTeX math is image-based by default** (snacks.image): needs a kitty-graphics
  terminal (Ghostty/kitty), ImageMagick (`magick`), a LaTeX compiler (`pdflatex`, or
  `tectonic` if present), and the `latex` treesitter parser. render-markdown's own text
  math is OFF (see the pinned fact + toggle). Text fallback (any terminal) uses `utftex`
  (`brew install utftex`, or build libtexprintf into `~/.local/bin` if brew is broken)
  then `latex2text` (`uv tool install pylatexenc`). With no renderer, math shows raw `$…$`.
- molten host venv at `~/.virtualenvs/neovim` with `pynvim`+`jupyter_client`
  (until present, `:UpdateRemotePlugins` warns — expected, not a bug)
- `debugpy` / `pytest` / `ipykernel` in each project venv (`uv add --dev …`)
- Neovim ≥ 0.12 (nvim-treesitter `main` branch), a Nerd Font, ImageMagick, a
  graphics terminal
- treesitter parsers `c`, `cpp`, `cmake`, `make`, `doxygen`, `printf` (installed by
  `treesitter.lua`; installing through nvim-treesitter is also what puts the
  **queries** on the runtimepath — Neovim itself bundles queries for only
  c/lua/markdown/query/vim/vimdoc, so `cpp` highlighting depends on this)

See `README.md` for the full setup walkthrough.
