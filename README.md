# 🌸 cute.nvim — a Python / AI-ML + C/C++ Neovim config

A hand-rolled, **uv-native** Neovim setup for Python and AI/ML work — plus a
first-class **C/C++** toolchain — wrapped in a **cute pink light theme** with a
**Nyan-cat statusline**. Neovim 0.12+, lazy.nvim.

- 🧠 **LSP** — [pyrefly](https://github.com/facebook/pyrefly) (Meta's type checker) for types & hover + [ruff](https://docs.astral.sh/ruff/) for lint / code actions / import sorting
- ⚙️ **C/C++** — clangd (with in-process clang-tidy), clang-format, lldb debugging, and **`<leader>rr` to compile & run anything** — one file or a whole CMake project. Needs nothing installed beyond Xcode's Command Line Tools.
- 🔍 **Hover-on-idle** — rest on a symbol for 3s (or `<leader>ch`) to pop its definition in a corner window that never covers your code; `<leader>cH` toggles it
- 🎨 **Format** — ruff via [conform.nvim](https://github.com/stevearc/conform.nvim), format-on-save
- ⚡ **Completion** — [blink.cmp](https://github.com/saghen/blink.cmp) with GitHub Copilot in the menu
- 🤖 **AI** — [copilot.lua](https://github.com/zbirenbaum/copilot.lua) + [CopilotChat](https://github.com/CopilotC-Nvim/CopilotChat.nvim) (browser login, **no API key**)
- 📓 **Jupyter / data science** — [molten](https://github.com/benlubas/molten-nvim) + [jupytext](https://github.com/GCBallesteros/jupytext.nvim) + [image.nvim](https://github.com/3rd/image.nvim) (inline plots)
- 🐞 **Debug / test** — nvim-dap + dap-python + [neotest](https://github.com/nvim-neotest/neotest) (pytest), all on the uv venv
- 📝 **Markdown** — [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim) live rendering (tables, callouts, **LaTeX math**), [vim-table-mode](https://github.com/dhruvasagar/vim-table-mode) auto-tables, [marksman](https://github.com/artempyanykh/marksman) LSP
- 🪟 **Windows · tabs · terminal** — quick splits (`<leader>w`), tabs (`<leader><Tab>`), and a toggleable bottom-split terminal on `~`
- 🌳 Treesitter, Telescope, oil, gitsigns, which-key, trouble, todo-comments, mini.\*
- 📦 **uv everywhere** — every Python tool targets the project's `.venv` automatically

> **Theme:** a faithful port of [webfreak's "Cute Pink Light"](https://marketplace.visualstudio.com/items?itemName=webfreak.cute-theme) VS Code theme.
> **Nyan cat:** the position indicator is based on [nyan-modoki.vim](https://github.com/nefo-mi/nyan-modoki.vim) (a port of [nyan-mode.el](https://github.com/TeMPOraL/nyan-mode)).

---

## Requirements

| Tool | Why | Install (macOS) |
|------|-----|-----------------|
| **Neovim ≥ 0.12** | nvim-treesitter `main` branch | `brew upgrade neovim` |
| **tree-sitter CLI** ≥ 0.26.1 | builds TS parsers (`main` branch) | `brew install tree-sitter-cli` (plain `tree-sitter` formula is library-only) — or prebuilt binary → `~/.local/bin` |
| **[uv](https://docs.astral.sh/uv/)** | Python env + running | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **Xcode Command Line Tools** | C/C++: clang, clangd, clang-format, lldb-dap | `xcode-select --install` |
| **CMake** *(optional)* | C/C++ project builds + ctest | `brew install cmake` |
| **Ninja** *(optional)* | faster CMake builds (auto-detected) | `brew install ninja` |
| **cmake-language-server** *(optional)* | LSP for `CMakeLists.txt` | `uv tool install cmake-language-server` |
| **ripgrep, fd** | Telescope | `brew install ripgrep fd` |
| **Node ≥ 22** | Copilot | `brew install node` |
| **A Nerd Font** | icons | `brew install --cask font-jetbrains-mono-nerd-font` |
| **ImageMagick** | inline images + math | `brew install imagemagick` |
| **Graphics terminal** | inline plots + **math images** | `brew install --cask ghostty` (or kitty) |
| **LaTeX** (`pdflatex`) | typeset math images | [MacTeX](https://tug.org/mactex/) / BasicTeX, or `brew install --cask mactex-no-gui` |
| **marksman** *(optional)* | Markdown LSP (links/headings) | `brew install marksman` |
| **utftex** / pylatexenc *(optional)* | text-math fallback (non-graphics terminals) | `brew install utftex` (2D) or `uv tool install pylatexenc` (`latex2text`) |

> **Inline images** (notebook plots) need a terminal speaking the **kitty graphics
> protocol** — Ghostty or kitty (WezTerm needs the `sixel` backend). In
> Terminal.app / iTerm2 images won't render, but text output still works.

## Install

```sh
# This repo IS your nvim config — clone it to ~/.config/nvim
git clone <your-repo-url> ~/.config/nvim

# Python language tools (uv puts them on PATH)
uv tool install pyrefly
uv tool install ruff

# C/C++ needs nothing extra — clangd, clang-format and lldb-dap all ship with
# the Command Line Tools (the config finds the off-PATH ones via `xcrun -f`):
xcode-select --install
brew install cmake                 # only for CMake projects + ctest

# Optional: richer Markdown (LSP completion + math rendering)
brew install marksman              # link / heading / reference completion
uv tool install pylatexenc         # `latex2text` → renders LaTeX math (or utftex)

# First launch installs all plugins, then:
nvim
#   :Lazy sync             — install/update plugins
#   :Copilot auth          — sign in to GitHub Copilot (browser)
#   :checkhealth           — verify rg / fd / node / providers
```

## uv workflow

The config resolves **one interpreter** for every Python tool — the active
`$VIRTUAL_ENV`, else the project's `.venv` (uv's default), found by walking up
for `.venv` / `pyproject.toml` / `uv.lock` / `.git`. No `source .venv/bin/activate`
needed; just launch `nvim` from inside the project.

```sh
uv init my-project && cd my-project
uv add numpy pandas                              # runtime deps
uv add --dev debugpy pytest ipython ipykernel    # dev tooling used by this config
nvim main.py
```

| Key | Action |
|-----|--------|
| `<leader>rr` | Run current file via `uv run` (bottom terminal) |
| `<leader>ri` | Open `uv run ipython` REPL |
| `<leader>rs` | `uv sync` |
| `<leader>ra` | `uv add <pkg>` (prompts) |

> After creating/changing the venv (`uv sync`), run `:LspRestart` so pyrefly/ruff
> re-resolve it. To **pin** the interpreter explicitly, add to `pyproject.toml`:
> ```toml
> [tool.pyrefly]
> python-interpreter-path = ".venv/bin/python"
> ```

## Jupyter / molten setup

molten is a Python *remote plugin*; its host needs `pynvim` + `jupyter_client`.
Use a dedicated venv (kept separate from your projects). Until you do this,
`:UpdateRemotePlugins` will warn — that's expected.

```sh
# 1. Dedicated Neovim Python host (init.lua auto-detects this path)
python3 -m venv ~/.virtualenvs/neovim
~/.virtualenvs/neovim/bin/python -m pip install \
  pynvim jupyter_client cairosvg pnglatex plotly kaleido nbformat ipykernel pillow

# 2. Per-project kernel (run inside your uv project)
uv add --dev ipykernel
uv run python -m ipykernel install --user --name my-project --display-name "Python (my-project)"
```

Then in Neovim: `:UpdateRemotePlugins` (once), restart, open a `.py`/`.ipynb`,
`<localleader>mi` to pick the kernel, and evaluate cells with `<localleader>e` /
`<localleader>rl`. `.ipynb` files open as `# %%`-delimited Python (full LSP) via
jupytext, and saved cell outputs round-trip.

## C / C++

Everything lives in [`lua/config/cc.lua`](lua/config/cc.lua) — the single source of
truth for how C/C++ is built, run and debugged (the mirror of `config/python.lua`).
**No extra plugins**: clangd, clang-format and lldb-dap all ship with the Xcode
Command Line Tools, and the two that aren't on `$PATH` are resolved through
`xcrun -f`.

### Compile & run: `<leader>rr`

One key, and it does the right thing for the buffer you're in:

| Your project | What `<leader>rr` does |
|--------------|------------------------|
| a lone `.c` / `.cpp` | compiles it to the cache dir (source tree stays clean) and runs it |
| a `CMakeLists.txt` above it | configures if needed → builds → runs the executable target |
| a `Makefile` above it | `make run` if that rule exists, else builds and runs the binary |

Compiler errors go to the **quickfix list**, typed and jumpable, with the cursor
dropped on the first one. Output appears in a reusable bottom split whose winbar
reports the exit code and wall time (`✓ hello · exit 0 · 12ms`). `q` closes it.

Two conveniences for exercises and competitive programming: if a `<name>.in` (or
`input.txt`) sits next to the source it is **piped to stdin automatically**, and
`<leader>rs` always compiles just the current file even inside a big project.

```
<leader>rr   build & run (smart)        <leader>rg   cmake configure (generate)
<leader>rs   build & run this file only <leader>rp   pick the CMake target
<leader>rb   build only (all targets)   <leader>rc   clean build products
<leader>rR   build & run with args…     <leader>rz   toggle asan + ubsan
<leader>ri   build & run with stdin…    <leader>ro   toggle Debug / Release
<leader>rl   re-run the last command    <leader>rv   pick the language standard
<leader>rq   build errors (quickfix)    <leader>rf   show the build settings
<leader>rn   write a project .clangd    <leader>rP   scaffold a CMakeLists.txt
<leader>tt   ctest (all)                <leader>tf   ctest — pick one test
<leader>dR   build with -g & debug      <leader>cS / ⌥o   switch source ↔ header
```

Same thing as commands, for scripting: `:CcRun`, `:CcBuild`, `:CcDebug`, `:CcTest`,
`:CcConfigure`, `:CcClean`, `:CcInfo`, `:CcClangd`, `:CcInit`.

### Defaults

`-std=c++23` / `-std=c17`, `-Wall -Wextra -Wpedantic`, `-g -O0`, 4-space indent,
100-column guide. `<leader>rf` prints the current settings; override them in your
own config, e.g. `require("config.cc").settings.std.cpp = "c++20"`.

`<leader>rz` turns on **AddressSanitizer + UBSan** (with
`-fno-sanitize-recover=undefined`, so undefined behaviour actually fails the run
instead of printing a note and exiting 0).

### clangd

Bare files work with no setup: a lone `.cpp` is told it's C++23 through clangd's
`fallbackFlags`, so `std::format`/`std::span`/ranges resolve without a
`compile_commands.json` anywhere. (C and C++ get separate clangd configs because
clangd rejects a C++ `-std` outright on a `.c` file.) CMake projects get a real
compilation database — `<leader>rg` passes `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`,
and clangd finds `build/compile_commands.json` on its own.

Inlay hints (parameter names, deduced types) are **on** in C/C++ buffers —
`<leader>ci` toggles them. clang-tidy runs *inside* clangd, so no separate binary
is needed; with no config, though, zero checks are enabled. `<leader>rn` writes a
project `.clangd` that turns on a sane set (`bugprone-*`, `performance-*`,
`modernize-*`, `readability-*`), pins the standard per file extension, and quiets
IncludeCleaner. On macOS the machine-wide equivalent lives at
`~/Library/Preferences/clangd/config.yaml` — **not** `~/.config/clangd`.

### Debugging

`<leader>dR` rebuilds with `-g` and launches lldb-dap; `<F5>`/`<leader>dc` and the
rest of the `<leader>d` maps behave as they do for Python. Breakpoints need the
debug info macOS keeps *outside* the binary in a sibling `.dSYM` bundle, which a
one-step `clang++ -g` build creates automatically — so build through
`<leader>dR`/`<leader>rb` rather than stripping or moving binaries by hand. The
debuggee's stdout appears in the dap REPL (`<leader>dr`); it has **no interactive
stdin**, because macOS refuses to let the adapter attach to its own Apple-signed
launcher process.

### Formatting

clang-format via conform, on save. A project `.clang-format` always wins; without
one, the fallback matches this config's editor defaults (LLVM style, 4-space
indent, 100 columns) so typing and formatting agree. Generate a project file with
`clang-format -style='{BasedOnStyle: LLVM, IndentWidth: 4, ColumnLimit: 100}' --dump-config > .clang-format`.

### Indentation

C/C++ use Neovim's built-in `cindent` with tuned `cinoptions` rather than
treesitter's experimental indent — namespaces and `extern "C"` don't add a level,
access specifiers sit at half a shiftwidth, and `case X: { … }` blocks and lambdas
indent correctly. Whole-file reflow is clang-format's job (`<leader>cf`).

## Markdown

Open any `.md` and it renders in-buffer — headings, lists, code blocks, tables,
callouts, and **LaTeX math** (`$…$` / `$$…$$`). Prose soft-wraps with spell-check on.

**Math renders as real typeset images** via [snacks.image](https://github.com/folke/snacks.nvim):
each formula is compiled with `pdflatex` and shown inline through the kitty graphics
protocol — so it needs a graphics terminal (Ghostty/kitty) + ImageMagick + a LaTeX
compiler. render-markdown handles everything else (headings, tables, callouts …).

| Key | Action |
|-----|--------|
| `<leader>mr` | Toggle live rendering (render-markdown) |
| `<leader>mt` | Toggle table mode — then typing a pipe auto-builds & aligns tables |
| `<leader>mT` | Tableize a visual selection (CSV/TSV → table) |

Optional installs unlock the extras (everything else works without them):

```sh
brew install marksman          # LSP: link / heading / reference completion
brew install utftex            # text-math fallback: 2D fraction bars, matrices, ∫/∑/√
uv tool install pylatexenc     # `latex2text` — flat text-math fallback
```

> **Image math** (the default) needs a kitty-graphics terminal, `magick`, and a LaTeX
> compiler (`pdflatex`/`tectonic`) — all driven by snacks.image, which conceals the
> source and shows the rendered formula inline. **Prefer text math** instead (any
> terminal, no images)? Set `latex = { enabled = true }` in `lua/plugins/markdown.lua`
> and `image = { math = { enabled = false } }` in `lua/plugins/snacks.lua`; text
> converters are tried in order — `utftex` (nice 2D) then `latex2text`. Either path
> needs the `latex` treesitter parser (built by the `tree-sitter` CLI). With no
> renderer at all, math shows as raw `$…$` source.

## Keymaps

Leader = `Space`, localleader = `\`. `<leader>?` shows buffer-local maps; which-key
hints every prefix.

| Prefix | Group | Highlights |
|--------|-------|------------|
| `<leader>f` | **find** | `ff` files · `fg` grep · `fb` buffers · `fr` recent · `/` in-buffer |
| `<leader>c` | **code / lsp** | `cr` rename · `ca` action · `co` organize · `cf` format · `cd` diag · `ch`/`cH` hover popup |
| `<leader>r` | **run / build** | *Python:* `rr` run · `ri` ipython · `rs` sync · `ra` add — *C/C++:* `rr` build&run · `rb` build · `rq` errors · `rz` sanitizers ([full list](#compile--run-leaderrr)) |
| `<leader>t` | **test** | `tt` nearest · `tf` file · `td` debug · `ts` summary · `to` output — *C/C++:* `tt`/`tf` ctest |
| `<leader>d` | **debug** | `db` breakpoint · `dc` continue · `du` UI · `dn` test method · `dR` build & debug (C/C++) |
| `<leader>a` | **AI (copilot)** | `aa` chat · `am` models · `ap` prompts · `aq` quick · (visual) `ae`/`af`/`at`/`ar` |
| `<leader>h` | **git hunk** | `hs` stage · `hr` reset · `hp` preview · `hb` blame · `]c`/`[c` nav |
| `<leader>x` | **diagnostics** | `xx` Trouble · `xX` buffer · `]d`/`[d` jump |
| `<leader>w` | **window** | `wv` split-v · `ws` split-h · `wc` close · `wo` only |
| `<leader><Tab>` | **tabs** | `n` new · `c` close · `]`/`[` next/prev · `o` only |
| `<leader>m` | **markdown** | `mr` render · `mt` table-mode · `mT` tableize |
| `~` | **terminal** | toggle a bottom-split shell — persists, respawns after `exit` |
| `<localleader>` | **Jupyter** | `mi` init · `e` eval-op · `rl` line · `rr` re-eval · `os` output · `]x`/`[x` cells |
| `gd` `K` `grn` `gra` | **LSP** | definition · hover · rename · code action (0.11 defaults) |
| `-` | oil | edit the filesystem as a buffer |

## Layout

```
init.lua                 leaders, host, load config/, bootstrap lazy, apply theme
lua/config/              options · keymaps · autocmds · python (uv resolver + run/repl)
                         cc (C/C++ toolchain: build · run · debug · filetypes)
lua/cute/                colorscheme (init) · lualine theme · nyan component
lua/plugins/             one file per concern (lsp, completion, copilot, dap, …)
colors/cute.lua          :colorscheme cute entrypoint
```

## Customizing

- **Theme:** edit the palette in `lua/cute/init.lua`. Prefer a maintained theme?
  Swap the `colorscheme` call in `init.lua` for catppuccin (latte) or rose-pine (dawn).
- **Per-machine tweaks:** create `lua/config/local.lua` (git-ignored) and
  `require("config.local")` from `init.lua`.
- **More LSP servers:** add `vim.lsp.config(name, {...})` + `vim.lsp.enable(name)`
  in `lua/plugins/lsp.lua`.

## License

[MIT](./LICENSE).
