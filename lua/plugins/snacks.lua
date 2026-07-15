-- Image-based LaTeX math for Markdown — snacks.image (kitty graphics protocol).
--   Compiles each $…$ / $$…$$ formula to a real typeset image
--   (pdflatex → PDF → ImageMagick → PNG) and shows it inline via the kitty
--   graphics protocol, concealing the source. This supersedes render-markdown's
--   text (utftex) math, which is turned off in lua/plugins/markdown.lua.
--
-- Requires (all present on this machine): a kitty-graphics terminal (Ghostty or
-- kitty), ImageMagick (`magick`), and a LaTeX compiler (pdflatex from TeX Live;
-- tectonic is used instead if installed). In a terminal without graphics, snacks
-- falls back to a float preview on cursor-hold.
--
-- image.nvim stays installed purely as molten's image provider; its markdown
-- integration is disabled (lua/plugins/datascience.lua) so exactly one library
-- owns markdown images. Only the `image` snacks module is enabled here.
return {
  "folke/snacks.nvim",
  -- snacks asks to load eagerly (its health check warns against lazy-loading);
  -- only the `image` module is enabled, so startup cost is minimal. Loading early
  -- registers the FileType autocmd before any markdown buffer opens.
  lazy = false,
  priority = 1000,
  ---@module 'snacks'
  ---@type snacks.Config
  opts = {
    image = {
      enabled = true,
      doc = {
        inline = true, -- render inline via kitty unicode placeholders
        float = true, -- float fallback when inline isn't possible
      },
      math = {
        enabled = true,
        latex = {
          font_size = "Large", -- \Large math — legible at terminal DPI
        },
      },
    },
  },
}
