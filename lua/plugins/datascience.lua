-- ============================================================================
-- Jupyter / data-science / AI-ML — molten + jupytext + image.nvim.
--   • Run code cells against a live Jupyter kernel; output (incl. plots/images)
--     renders inline IF your terminal supports the kitty graphics protocol
--     (Ghostty, kitty; WezTerm needs the sixel backend). Plain Terminal.app /
--     iTerm2 won't show images — text output still works.
--   • Edit .ipynb notebooks as `# %%`-delimited Python (jupytext), with full LSP.
--
-- One-time setup (see README → "Jupyter / molten setup"):
--   • dedicated Neovim python host with pynvim + jupyter_client (g:python3_host_prog)
--   • per-project kernel via uv:  uv add --dev ipykernel
--                                 uv run python -m ipykernel install --user --name <proj>
--   • :UpdateRemotePlugins runs automatically via the build step below.
-- ============================================================================
return {
  -- Inline image rendering ----------------------------------------------------
  {
    "3rd/image.nvim",
    -- magick_rock users: dependencies = { "vhyrro/luarocks.nvim" }
    opts = {
      backend = "kitty", -- Ghostty / kitty (WezTerm: use "sixel")
      processor = "magick_cli", -- shells out to ImageMagick (brew install imagemagick)
      integrations = { markdown = { enabled = true } },
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "blink-cmp-menu", "" },
    },
  },

  -- Jupyter kernel runtime ----------------------------------------------------
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    ft = { "python", "markdown", "quarto" },
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_image_location = "both"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true
      vim.g.molten_cover_empty_lines = true
    end,
    config = function()
      local map = vim.keymap.set
      -- Lifecycle
      map("n", "<localleader>mi", ":MoltenInit<CR>", { silent = true, desc = "Molten: init kernel" })
      map("n", "<localleader>md", ":MoltenDeinit<CR>", { silent = true, desc = "Molten: deinit kernel" })
      -- Run
      map("n", "<localleader>e", ":MoltenEvaluateOperator<CR>", { silent = true, desc = "Molten: eval operator" })
      map("n", "<localleader>rl", ":MoltenEvaluateLine<CR>", { silent = true, desc = "Molten: eval line" })
      map("v", "<localleader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", { silent = true, desc = "Molten: eval visual" })
      map("n", "<localleader>rr", ":MoltenReevaluateCell<CR>", { silent = true, desc = "Molten: re-eval cell" })
      map("n", "<localleader>ri", ":MoltenInterrupt<CR>", { silent = true, desc = "Molten: interrupt" })
      map("n", "<localleader>rd", ":MoltenDelete<CR>", { silent = true, desc = "Molten: delete cell" })
      -- Output
      map("n", "<localleader>oh", ":MoltenHideOutput<CR>", { silent = true, desc = "Molten: hide output" })
      map("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>", { silent = true, desc = "Molten: enter output" })
      map("n", "<localleader>oi", ":MoltenImagePopup<CR>", { silent = true, desc = "Molten: image popup" })
      -- Navigate cells
      map("n", "]x", ":MoltenNext<CR>", { silent = true, desc = "Molten: next cell" })
      map("n", "[x", ":MoltenPrev<CR>", { silent = true, desc = "Molten: prev cell" })

      -- Auto-init kernel from a notebook's metadata + import/export saved outputs.
      local aug = vim.api.nvim_create_augroup("cute_molten", { clear = true })
      vim.api.nvim_create_autocmd("BufAdd", {
        group = aug,
        pattern = { "*.ipynb" },
        callback = function(e)
          vim.schedule(function()
            local kernels = vim.fn.MoltenAvailableKernels()
            local ok, name = pcall(function()
              return vim.json.decode(io.open(e.file, "r"):read("a"))["metadata"]["kernelspec"]["name"]
            end)
            if ok and vim.tbl_contains(kernels, name) then
              vim.cmd(("MoltenInit %s"):format(name))
            end
            pcall(vim.cmd, "MoltenImportOutput")
          end)
        end,
      })
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = aug,
        pattern = { "*.ipynb" },
        callback = function()
          local ok, status = pcall(require, "molten.status")
          if ok and status.initialized() == "Molten" then
            pcall(vim.cmd, "MoltenExportOutput!")
          end
        end,
      })
    end,
  },

  -- Edit .ipynb as a py:percent script ---------------------------------------
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- must intercept reading .ipynb files
    opts = {
      style = "percent", -- "# %%" cells => native python + LSP/treesitter
      output_extension = "py",
      force_ft = "python",
    },
  },
}
