# 🌸 cute.nvim — a Python / AI-ML Neovim config

A hand-rolled, **uv-native** Neovim setup for Python and AI/ML work, wrapped in a
**cute pink light theme** with a **Nyan-cat statusline**. Neovim 0.12+, lazy.nvim.

- 🧠 **LSP** — [pyrefly](https://github.com/facebook/pyrefly) (Meta's type checker) for types & hover + [ruff](https://docs.astral.sh/ruff/) for lint / code actions / import sorting
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
| `<leader>r` | **run / uv** | `rr` run · `ri` ipython · `rs` sync · `ra` add |
| `<leader>t` | **test** | `tt` nearest · `tf` file · `td` debug · `ts` summary · `to` output |
| `<leader>d` | **debug** | `db` breakpoint · `dc` continue · `du` UI · `dn` test method |
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
