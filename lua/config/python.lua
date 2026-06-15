-- ============================================================================
-- uv integration. Single source of truth for "which Python interpreter".
-- Every Python tool in this config (pyrefly, ruff, dap-python, neotest, molten
-- kernels) resolves the interpreter through `venv_python()` so they all target
-- the SAME uv-managed environment without manual `source .venv/bin/activate`.
--
-- Resolution order:
--   1. $VIRTUAL_ENV         (an already-activated venv wins)
--   2. <project>/.venv      (uv's default; found by walking up for .venv / pyproject.toml / .git)
--   3. nil                  (callers fall back to system `python3`)
-- ============================================================================
local M = {}

local uv = vim.uv or vim.loop

--- Absolute path to the project's uv-managed python, or nil.
---@return string|nil
function M.venv_python()
  -- 1. Active virtualenv.
  local active = vim.env.VIRTUAL_ENV
  if active and active ~= "" then
    local p = active .. "/bin/python"
    if uv.fs_stat(p) then
      return p
    end
  end

  -- 2. Project-root .venv (uv default layout).
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.fn.getcwd()
  end
  local root = vim.fs.root(start, { ".venv", "pyproject.toml", "uv.lock", ".git" })
  if root then
    local p = root .. "/.venv/bin/python"
    if uv.fs_stat(p) then
      return p
    end
  end

  return nil
end

--- Project python with a guaranteed string (system fallback) — for callers that
--- need a concrete path (dap-python, neotest).
---@return string
function M.python()
  return M.venv_python() or vim.fn.exepath("python3") or "python3"
end

--- The uv project root (dir containing pyproject.toml / uv.lock / .venv), or cwd.
---@return string
function M.project_root()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.fn.getcwd()
  end
  return vim.fs.root(start, { "pyproject.toml", "uv.lock", ".venv", ".git" }) or vim.fn.getcwd()
end

-- ---------------------------------------------------------------------------
-- Running / REPL via uv
-- ---------------------------------------------------------------------------

--- Open a bottom split terminal running `uv run <current file>`.
function M.run_file()
  if vim.bo.filetype ~= "python" then
    vim.notify("Not a Python buffer", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    vim.cmd.write()
  end
  local file = vim.fn.expand("%:p")
  vim.cmd("botright split | resize 15")
  vim.cmd("terminal cd " .. vim.fn.fnameescape(M.project_root()) .. " && uv run " .. vim.fn.fnameescape(file))
  vim.cmd("startinsert")
end

--- Open a right split terminal with an interactive `uv run ipython` REPL
--- (falls back to `uv run python` if ipython isn't in the venv).
function M.repl()
  local repl = (vim.fn.executable("ipython") == 1 or M.venv_python()) and "ipython" or "python"
  vim.cmd("botright vsplit")
  vim.cmd(
    "terminal cd "
      .. vim.fn.fnameescape(M.project_root())
      .. " && uv run "
      .. repl
      .. " 2>/dev/null || uv run python"
  )
  vim.cmd("startinsert")
end

--- Run an async `uv <args...>` and report stdout/stderr via notify.
---@param args string[]
local function uv_cmd(args)
  vim.notify("uv " .. table.concat(args, " ") .. " …", vim.log.levels.INFO)
  vim.system(
    vim.list_extend({ "uv" }, args),
    { text = true, cwd = M.project_root() },
    vim.schedule_wrap(function(res)
      local out = (res.stdout or "") .. (res.stderr or "")
      vim.notify(out ~= "" and out or ("uv " .. args[1] .. " done"), vim.log.levels.INFO)
    end)
  )
end

function M.sync()
  uv_cmd({ "sync" })
end

function M.add()
  vim.ui.input({ prompt = "uv add: " }, function(pkg)
    if pkg and pkg ~= "" then
      uv_cmd(vim.list_extend({ "add" }, vim.split(pkg, "%s+")))
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Keymaps  (<leader>r = "run / uv")
-- ---------------------------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>rr", M.run_file, { desc = "uv run current file" })
map("n", "<leader>ri", M.repl, { desc = "uv run ipython (REPL)" })
map("n", "<leader>rs", M.sync, { desc = "uv sync" })
map("n", "<leader>ra", M.add, { desc = "uv add <pkg>" })

return M
