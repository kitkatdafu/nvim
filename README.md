# 🌸 cute.nvim — a Python / AI-ML Neovim config

A hand-rolled, **uv-native** Neovim setup for Python and AI/ML work, wrapped in a
**cute pink light theme** with a **Nyan-cat statusline**. Neovim 0.11+, lazy.nvim.

- 🧠 **LSP** — [pyrefly](https://github.com/facebook/pyrefly) (Meta's type checker) for types & hover + [ruff](https://docs.astral.sh/ruff/) for lint / code actions / import sorting
- 🎨 **Format** — ruff via [conform.nvim](https://github.com/stevearc/conform.nvim), format-on-save
- ⚡ **Completion** — [blink.cmp](https://github.com/saghen/blink.cmp) with GitHub Copilot in the menu
- 🤖 **AI** — [copilot.lua](https://github.com/zbirenbaum/copilot.lua) + [CopilotChat](https://github.com/CopilotC-Nvim/CopilotChat.nvim) (browser login, **no API key**)
- 📓 **Jupyter / data science** — [molten](https://github.com/benlubas/molten-nvim) + [jupytext](https://github.com/GCBallesteros/jupytext.nvim) + [image.nvim](https://github.com/3rd/image.nvim) (inline plots)
- 🐞 **Debug / test** — nvim-dap + dap-python + [neotest](https://github.com/nvim-neotest/neotest) (pytest), all on the uv venv
- 🌳 Treesitter, Telescope, oil, gitsigns, which-key, trouble, todo-comments, mini.\*
- 📦 **uv everywhere** — every Python tool targets the project's `.venv` automatically

> **Theme:** a faithful port of [webfreak's "Cute Pink Light"](https://marketplace.visualstudio.com/items?itemName=webfreak.cute-theme) VS Code theme.
> **Nyan cat:** the position indicator is based on [nyan-modoki.vim](https://github.com/nefo-mi/nyan-modoki.vim) (a port of [nyan-mode.el](https://github.com/TeMPOraL/nyan-mode)).

---

## Requirements

| Tool | Why | Install (macOS) |
|------|-----|-----------------|
| **Neovim ≥ 0.11.7** | telescope's minimum | `brew upgrade neovim` |
| **[uv](https://docs.astral.sh/uv/)** | Python env + running | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **ripgrep, fd** | Telescope | `brew install ripgrep fd` |
| **Node ≥ 22** | Copilot | `brew install node` |
| **A Nerd Font** | icons | `brew install --cask font-jetbrains-mono-nerd-font` |
| **ImageMagick** | inline images | `brew install imagemagick` |
| **Graphics terminal** | inline plots | `brew install --cask ghostty` (or kitty) |

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

## Keymaps

Leader = `Space`, localleader = `\`. `<leader>?` shows buffer-local maps; which-key
hints every prefix.

| Prefix | Group | Highlights |
|--------|-------|------------|
| `<leader>f` | **find** | `ff` files · `fg` grep · `fb` buffers · `fr` recent · `/` in-buffer |
| `<leader>c` | **code / lsp** | `cr` rename · `ca` action · `cf` format · `co` organize imports · `cd` diagnostics |
| `<leader>r` | **run / uv** | `rr` run · `ri` ipython · `rs` sync · `ra` add |
| `<leader>t` | **test** | `tt` nearest · `tf` file · `td` debug · `ts` summary · `to` output |
| `<leader>d` | **debug** | `db` breakpoint · `dc` continue · `du` UI · `dn` test method |
| `<leader>a` | **AI (copilot)** | `aa` chat · `am` models · `ap` prompts · `aq` quick · (visual) `ae`/`af`/`at`/`ar` |
| `<leader>h` | **git hunk** | `hs` stage · `hr` reset · `hp` preview · `hb` blame · `]c`/`[c` nav |
| `<leader>x` | **diagnostics** | `xx` Trouble · `xX` buffer · `]d`/`[d` jump |
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
