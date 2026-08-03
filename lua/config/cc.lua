-- ============================================================================
-- C / C++ integration. Single source of truth for "how do I build, run and
-- debug this code" — what config/python.lua is for uv, this is for the C family.
--
-- Every C/C++ tool in the config resolves through here: clangd's argv
-- (lua/plugins/lsp.lua), clang-format's path (conform.lua), the lldb-dap
-- adapter (dap.lua), and the <leader>r build/run keymaps at the bottom.
--
-- Two modes, chosen per buffer, no configuration:
--   • project — the file sits under a CMakeLists.txt or a Makefile: build with
--               cmake/make, run a *target* (targets come from CMake's File API).
--   • single  — a lone .c/.cpp (exercises, scratch code, competitive
--               programming): compiled straight to the cache dir and run.
-- <leader>rr does the right one; <leader>rs always forces single-file.
--
-- macOS: the Xcode Command Line Tools already ship clangd, clang-format AND
-- lldb-dap, but only put some of them on $PATH — `xcrun -f <tool>` finds the
-- rest, so a stock Mac needs nothing installed. See M.tool().
-- ============================================================================
local M = {}

local uv = vim.uv or vim.loop

-- ---------------------------------------------------------------------------
-- Settings. Override from your own config *before* anything builds, e.g.
--   require("config.cc").settings.std.cpp = "c++20"
-- ---------------------------------------------------------------------------
M.settings = {
  std = { c = "c17", cpp = "c++23" }, -- Apple clang 21 accepts up to c++26 / c23
  build_type = "Debug", -- "Debug" (-O0 -g) | "Release" (-O2 -DNDEBUG)
  sanitize = false, -- -fsanitize=address,undefined
  warnings = { "-Wall", "-Wextra", "-Wpedantic" },
  build_dir = "build", -- CMake binary dir, relative to the project root
  height = 15, -- height of the run split
  indent = 4, -- shiftwidth for C/C++ buffers (matches the clang-format fallback)
  column = 100, -- colorcolumn (matches the clang-format fallback ColumnLimit)
  jobs = (uv.available_parallelism and uv.available_parallelism()) or 4,
}

-- Per-project CMake/make target choice, keyed by project root.
local chosen_target = {}

-- ---------------------------------------------------------------------------
-- 1. Tool discovery
-- ---------------------------------------------------------------------------
local tool_cache = {}

--- Absolute path to a toolchain binary, or nil. Falls back to `xcrun -f` so the
--- Command Line Tools' clang-format / lldb-dap are found without $PATH surgery.
---@param name string
---@return string|nil
function M.tool(name)
  local hit = tool_cache[name]
  if hit ~= nil then
    return hit or nil
  end
  local path = vim.fn.exepath(name)
  if path == "" and vim.fn.executable("xcrun") == 1 then
    local res = vim.system({ "xcrun", "-f", name }, { text = true }):wait()
    if res.code == 0 then
      path = vim.trim(res.stdout or "")
    end
  end
  if path ~= "" and vim.fn.executable(path) == 1 then
    tool_cache[name] = path
  else
    tool_cache[name] = false
  end
  return tool_cache[name] or nil
end

--- argv for clangd — flags chosen so a bare file and a full CMake project both
--- behave. Consumed by lua/plugins/lsp.lua.
---@return string[]
function M.clangd_cmd()
  return {
    M.tool("clangd") or "clangd",
    "--background-index", -- index the project on idle, persist to disk
    "--clang-tidy", -- lint in-process (no clang-tidy binary needed)
    "--completion-style=detailed",
    "--header-insertion=iwyu", -- add the owning #include when completing
    "--function-arg-placeholders=1",
    "--all-scopes-completion",
    "--enable-config", -- read .clangd / clangd/config.yaml
    "--fallback-style=LLVM",
    "--pch-storage=memory",
    "-j=" .. M.settings.jobs,
  }
end

--- Resolved clang-format path (CLT ships it off-PATH). Consumed by conform.lua.
---@return string|nil
function M.clang_format()
  return M.tool("clang-format")
end

--- Resolved lldb-dap path (CLT ships it off-PATH). Consumed by dap.lua.
---@return string|nil
function M.lldb_dap()
  return M.tool("lldb-dap")
end

-- ---------------------------------------------------------------------------
-- 2. Project detection
-- ---------------------------------------------------------------------------
local SOURCE_FT = { c = true, cpp = true, cuda = true, objc = true, objcpp = true }

-- The last C-family buffer that was current. Running a program moves the cursor
-- into the run terminal, and the quickfix window isn't a file either — so every
-- "which project is this?" question has to be answered from the source buffer,
-- not from whatever window happens to be focused.
local last_source = nil

--- The buffer the build commands should act on.
---@return integer
local function source_buf()
  local cur = vim.api.nvim_get_current_buf()
  if not SOURCE_FT[vim.bo[cur].filetype] and last_source and vim.api.nvim_buf_is_valid(last_source) then
    return last_source
  end
  return cur
end

--- A path to start searching from — guaranteed non-empty, because vim.fs.root
--- asserts on "" and getcwd() *is* empty when the cwd has been deleted under us
--- (a checkout, a cleaned build dir).
local function bufpath(buf)
  local name = vim.api.nvim_buf_get_name(buf or source_buf())
  if name ~= "" then
    return name
  end
  local cwd = vim.fn.getcwd()
  if cwd ~= "" then
    return cwd
  end
  local ok, real = pcall(uv.cwd)
  if ok and real and real ~= "" then
    return real
  end
  return vim.env.HOME or vim.fn.stdpath("cache")
end

--- The directory to act in: the buffer's own directory, or bufpath() itself when
--- that is already a directory (which it is for a buffer with no file name).
---@return string
local function bufdir(buf)
  local path = bufpath(buf)
  local stat = uv.fs_stat(path)
  if stat and stat.type == "directory" then
    return path
  end
  return vim.fs.dirname(path)
end

--- Directory of the build system that owns this file.
--- vim.fs.root() stops at the *nearest* marker, which is wrong for CMake: a
--- project with `add_subdirectory(src)` has a CMakeLists.txt in src/ too, and
--- configuring that one builds a fragment of the project. So for CMakeLists.txt
--- keep climbing while the parent has one as well.
---@return string
function M.root(buf)
  local start = bufpath(buf)
  local cmake = vim.fs.root(start, { "CMakeLists.txt" })
  if cmake then
    local parent = vim.fs.dirname(cmake)
    while parent and parent ~= cmake and uv.fs_stat(parent .. "/CMakeLists.txt") do
      cmake = parent
      parent = vim.fs.dirname(cmake)
    end
    return cmake
  end
  return vim.fs.root(start, {
    "Makefile",
    "makefile",
    "GNUmakefile",
    "compile_commands.json",
    "compile_flags.txt",
    ".clangd",
  }) or bufdir(buf)
end

--- "cmake" | "make" | "single" — which build path <leader>rr takes.
---@return string
function M.kind(buf)
  local start = bufpath(buf)
  if vim.fs.root(start, { "CMakeLists.txt" }) then
    return "cmake"
  end
  if vim.fs.root(start, { "Makefile", "makefile", "GNUmakefile" }) then
    return "make"
  end
  return "single"
end

--- The CMake binary dir for this buffer's project.
---@return string
function M.build_dir(buf)
  return M.root(buf) .. "/" .. M.settings.build_dir
end

-- ---------------------------------------------------------------------------
-- 3. Diagnostics → quickfix
-- ---------------------------------------------------------------------------
-- Neovim's default 'errorformat' is not usable for clang: it types nothing
-- (" error: " gets swallowed into %m, so nothing can tell errors from notes) and
-- it turns every include-chain breadcrumb into a junk entry. Patterns are
-- END-ANCHORED, which is the whole reason the built-in
-- "In file included from %f:%l" never matches clang's "foo.cpp:1:".
-- Compilers are called with -fno-color-diagnostics (an ANSI escape ends up
-- *inside* %f, making the entry unopenable) and -fdiagnostics-absolute-paths.
M.errorformat = table.concat({
  -- the snippet / caret art and the trailing tally clang wraps around each one
  "%-G%*[ 0-9]|%.%#",
  "%-G%*[0-9] warning%.%#",
  "%-G%*[0-9] error%.%#",
  -- include + instantiation breadcrumbs (clang's form carries no column)
  "%-GIn file included from %f:%l:%c:",
  "%-GIn file included from %f:%l:",
  "%-G%*[ ]from %f:%l:%c:",
  "%-G%*[ ]from %f:%l:",
  -- build-tool chatter. The ": " is load-bearing: a bare "%-Gmake%.%#" would
  -- silently swallow real diagnostics from a file named make_helpers.cpp.
  "%-G[%*[ 0-9]%%] %.%#",
  "%-Gmake: %.%#",
  "%-Gmake[%*[0-9]]: %.%#",
  "%-Gninja: %.%#",
  -- diagnostics. The %t single-char trick is what types them: e/w/n render as
  -- error/warning/note, so :cnext, Trouble and the statusline can discriminate.
  "%f:%l:%c: %tarning: %m",
  "%f:%l:%c: fatal %trror: %m",
  "%f:%l:%c: %trror: %m",
  "%f:%l:%c: %tote: %m",
  "%f:%l:%c: %m",
  "%f:%l: %tarning: %m",
  "%f:%l: fatal %trror: %m",
  "%f:%l: %trror: %m",
  "%f:%l: %tote: %m",
  "%f:%l: %m",
  -- driver-level failures, which carry no location
  "%Efatal error: %m",
  "%Eclang%.%#: error: %m",
  "%Wclang%.%#: warning: %m",
  -- ld's undefined-symbol block: worth showing, but genuinely not jumpable —
  -- it names an object file (`_main in foo.o`), never a source line.
  "%-GUndefined symbols for architecture%.%#",
  '%E  "%m"\\, referenced from:',
  "%C%*[ ]%m",
  "%Eld: error: %m",
  "%Wld: warning: %m",
  "%Eld: %m",
}, ",")

local QF_PREFIX = "cc: "

--- A hand-written Makefile usually compiles with paths relative to the project
--- root, and quickfix resolves those against *Neovim's* cwd. Re-anchor entries
--- whose file only exists under `root`, otherwise <CR> opens an empty buffer.
---@param root string
local function anchor_quickfix(root)
  if not root or root == vim.fn.getcwd() then
    return
  end
  local items, fixed = vim.fn.getqflist(), false
  for _, item in ipairs(items) do
    if item.valid == 1 and item.bufnr and item.bufnr > 0 then
      local name = vim.api.nvim_buf_get_name(item.bufnr)
      if name ~= "" and vim.fn.filereadable(name) == 0 then
        local candidate = root .. "/" .. vim.fs.normalize(name):gsub("^" .. vim.pesc(vim.fn.getcwd()) .. "/", "")
        if vim.fn.filereadable(candidate) == 1 then
          item.filename, item.bufnr, fixed = candidate, nil, true
        end
      end
    end
  end
  if fixed then
    local title = vim.fn.getqflist({ title = 1 }).title
    vim.fn.setqflist({}, "r", { title = title, items = items })
  end
end

--- Put compiler output in the quickfix list. Returns #errors, #warnings.
---@param lines string[]
---@param title string
---@param root? string  re-anchor relative paths against this directory
local function to_quickfix(lines, title, root)
  vim.fn.setqflist({}, " ", { title = QF_PREFIX .. title, lines = lines, efm = M.errorformat })
  if root then
    anchor_quickfix(root)
  end
  local errors, warnings = 0, 0
  for _, item in ipairs(vim.fn.getqflist()) do
    -- `%trror`/`%tarning` yield lowercase e/w; only the %E/%W-prefixed linker
    -- and driver patterns yield uppercase. Normalise, or warnings never count.
    local kind = (item.type or ""):upper()
    if item.valid == 1 then
      if kind == "E" then
        errors = errors + 1
      elseif kind == "W" then
        warnings = warnings + 1
      end
    end
  end
  return errors, warnings
end

--- Compilers put diagnostics on stderr and progress chatter on stdout; prefer
--- stderr so `[ 50%] Building …` lines never reach the quickfix parser.
local function split_output(res)
  local text = res.stderr or ""
  if vim.trim(text) == "" then
    text = res.stdout or ""
  end
  return vim.split(text, "\n", { trimempty = true })
end

--- vim.system() reports a signal death (a sanitizer abort is SIGABRT) as
--- code = 0, signal = 6 — so a bare `code ~= 0` check would call it a success.
local function failed(res)
  return res.code ~= 0 or (res.signal or 0) ~= 0
end

--- Transient one-line status (no message history, unlike vim.notify).
local function echo(msg, hl)
  vim.api.nvim_echo({ { msg, hl or "MoreMsg" } }, false, {})
end

--- Open the quickfix list at the first error.
function M.quickfix()
  vim.cmd("botright copen 10")
  pcall(vim.cmd.cfirst)
end

--- Close the quickfix window, but only when it's showing *our* build output —
--- never yank away a list the user opened for grep/diagnostics.
local function close_quickfix()
  local title = vim.fn.getqflist({ title = 1 }).title or ""
  if vim.startswith(title, QF_PREFIX) then
    vim.cmd("cclose")
  end
end

--- Shared tail of every build: parse the output into the quickfix list, report,
--- and continue with `done` only when the build actually succeeded.
---@param res table  the vim.system() result
---@param title string
---@param done? fun()
---@param root? string  directory to re-anchor relative diagnostic paths against
local function finish_build(res, title, done, root)
  local errors, warnings = to_quickfix(split_output(res), title, root)
  if failed(res) then
    vim.notify(("%s failed — %d error(s)"):format(title, math.max(errors, 1)), vim.log.levels.ERROR)
    M.quickfix()
    return
  end
  if warnings > 0 then
    echo(("  %s — %d warning(s), <leader>rq"):format(title, warnings), "WarningMsg")
  else
    close_quickfix()
    echo("  " .. title .. " ok")
  end
  if done then
    done()
  end
end

-- ---------------------------------------------------------------------------
-- 4. The run window — one reusable bottom split, exit code + wall time in its
--    winbar. jobstart{term=true} needs a fresh (unmodified) buffer each run,
--    since a terminal buffer is bound to exactly one job.
-- ---------------------------------------------------------------------------
local runner = { win = nil, buf = nil, job = nil, last = nil }

local function job_alive(job)
  return job and job > 0 and vim.fn.jobwait({ job }, 0)[1] == -1
end

---@param cmd string[]|string  argv, or a shell line when redirection is needed
---@param opts { cwd?:string, title?:string }
local function terminal(cmd, opts)
  opts = opts or {}
  runner.last = { cmd = cmd, opts = opts }

  if job_alive(runner.job) then
    pcall(vim.fn.jobstop, runner.job)
  end
  -- Reuse the run window only while it is still showing the run output. Once
  -- something else has been opened there it is the user's window, and taking it
  -- over would replace the file they're editing.
  local reusable = runner.win
    and vim.api.nvim_win_is_valid(runner.win)
    and runner.buf
    and vim.api.nvim_win_get_buf(runner.win) == runner.buf
  if reusable then
    vim.api.nvim_set_current_win(runner.win)
  else
    vim.cmd("botright " .. M.settings.height .. "split")
    runner.win = vim.api.nvim_get_current_win()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(runner.win, buf)
  if runner.buf and vim.api.nvim_buf_is_valid(runner.buf) and runner.buf ~= buf then
    pcall(vim.api.nvim_buf_delete, runner.buf, { force = true })
  end
  runner.buf = buf
  -- Die with the window rather than lingering as an unlisted dead terminal.
  vim.bo[buf].bufhidden = "wipe"

  -- 'winbar' is a statusline-format option: a stray "%" (a file called 50%.cpp,
  -- or args like `--rate 50%`) raises E539 and would abort the run entirely.
  local win, title = runner.win, ((opts.title or "run"):gsub("%%", "%%%%"))
  vim.wo[win].winbar = "  " .. title
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  local started = uv.hrtime()
  local job = vim.fn.jobstart(cmd, {
    term = true,
    cwd = opts.cwd,
    env = opts.env,
    on_exit = function(_, code)
      local ms = math.floor((uv.hrtime() - started) / 1e6)
      if vim.api.nvim_win_is_valid(win) then
        local mark = code == 0 and "  " or "  "
        vim.wo[win].winbar = ("%s%s · exit %d · %dms"):format(mark, title, code, ms)
      end
    end,
  })
  runner.job = job
  if job <= 0 then
    vim.notify("could not start: " .. vim.inspect(cmd), vim.log.levels.ERROR)
    return
  end

  -- Closing the split stops the program too. A still-running process with no
  -- window is worse than a lost log — and it would hold its pty until the next
  -- build reused the slot.
  vim.api.nvim_create_autocmd("BufWinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if job_alive(job) then
        pcall(vim.fn.jobstop, job)
      end
    end,
  })

  -- q closes the window (and stops the program with it); the source window is
  -- one <C-k> away, and <Esc><Esc> leaves terminal mode as everywhere else.
  vim.keymap.set("n", "q", function()
    if job_alive(runner.job) then
      pcall(vim.fn.jobstop, runner.job)
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true, desc = "Close run window" })

  vim.cmd.startinsert()
end

--- The shell line that actually launches a program. Everything goes through
--- `sh -c '…; exit $?'` on purpose: without the trailing `exit`, sh
--- exec-optimizes the child and a death by signal (a sanitizer abort, a
--- segfault) is reported as exit 0. Run args are intentionally *not* escaped —
--- the prompt behaves like a shell, so quotes and globs work.
---@param bin string
---@param args? string
---@param stdin? string
---@return string[]
local function launch_cmd(bin, args, stdin)
  local script = vim.fn.shellescape(bin)
  if args and args ~= "" then
    script = script .. " " .. args
  end
  if stdin and stdin ~= "" then
    script = script .. " < " .. vim.fn.shellescape(stdin)
  end
  return { "/bin/sh", "-c", script .. "; exit $?" }
end

--- Re-run the last command (same argv, same cwd).
function M.rerun()
  if not runner.last then
    vim.notify("Nothing has been run yet", vim.log.levels.WARN)
    return
  end
  terminal(runner.last.cmd, runner.last.opts)
end

-- ---------------------------------------------------------------------------
-- 5. Single-file mode
-- ---------------------------------------------------------------------------
--- Where a single file's binary goes: the cache dir, keyed by the source's
--- directory, so the source tree stays clean and two same-named files in
--- different folders never collide.
---@return string
local function cache_bin(file, create)
  local dir = ("%s/cute-cc/%s"):format(vim.fn.stdpath("cache"), vim.fn.sha256(vim.fs.dirname(file)):sub(1, 12))
  if create then
    vim.fn.mkdir(dir, "p")
  end
  return dir .. "/" .. vim.fn.fnamemodify(file, ":t:r")
end

--- Compiler argv for one translation unit straight to an executable.
local function compile_argv(file, ft, out)
  local is_c = ft == "c"
  local cc = M.tool(is_c and "clang" or "clang++") or (is_c and "cc" or "c++")
  local argv = { cc, "-std=" .. (is_c and M.settings.std.c or M.settings.std.cpp) }
  vim.list_extend(argv, M.settings.warnings)
  if M.settings.build_type == "Release" then
    vim.list_extend(argv, { "-O2", "-DNDEBUG" })
  else
    vim.list_extend(argv, { "-O0", "-g" })
  end
  if M.settings.sanitize then
    -- -fno-sanitize-recover is not optional: UBSan otherwise prints the
    -- diagnostic, keeps going and exits 0, so a run would look successful.
    vim.list_extend(argv, {
      "-fsanitize=address,undefined",
      "-fno-sanitize-recover=undefined",
      "-fno-omit-frame-pointer",
      "-g",
    })
  end
  -- Both are load-bearing for the quickfix list: an ANSI escape would be
  -- captured *into* the filename, and relative paths resolve against Neovim's
  -- cwd rather than the compiler's.
  vim.list_extend(argv, { "-fno-color-diagnostics", "-fdiagnostics-absolute-paths" })
  vim.list_extend(argv, { file, "-o", out })
  return argv
end

--- Sanitizer runtime knobs for the *run* step. detect_leaks is deliberately
--- absent: it is unsupported on macOS arm64 and aborts even correct programs.
local function run_env()
  if not M.settings.sanitize then
    return nil
  end
  return {
    UBSAN_OPTIONS = "print_stacktrace=1:halt_on_error=1",
    ASAN_OPTIONS = "abort_on_error=1",
  }
end

--- Compile the current buffer's file. Calls `done(binary)` only on success;
--- errors land in the quickfix list.
---@param done fun(binary: string)
function M.compile_single(done)
  local buf = source_buf()
  local ft = vim.bo[buf].filetype
  if not SOURCE_FT[ft] then
    vim.notify("Not a C/C++ buffer", vim.log.levels.WARN)
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    vim.notify("Save the buffer first", vim.log.levels.WARN)
    return
  end
  local HEADER = { h = true, hpp = true, hh = true, hxx = true, ipp = true, tpp = true, inl = true }
  if HEADER[vim.fn.fnamemodify(file, ":e")] then
    vim.notify("Headers aren't compiled on their own — switch to the source (⌥o)", vim.log.levels.WARN)
    return
  end
  if vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.write()
    end)
  end

  local out = cache_bin(file, true)
  local argv = compile_argv(file, ft, out)
  local name = vim.fs.basename(file)
  echo("  compiling " .. name .. " …")
  vim.system(argv, { text = true, cwd = vim.fs.dirname(file) }, function(res)
    vim.schedule(function()
      finish_build(res, name, function()
        done(out)
      end)
    end)
  end)
end

--- An input file to feed the program on stdin: `<stem>.in`, then `input.txt`.
---@return string|nil
local function default_stdin(file)
  local dir = vim.fs.dirname(file)
  for _, candidate in ipairs({ vim.fn.fnamemodify(file, ":r") .. ".in", dir .. "/input.txt" }) do
    if uv.fs_stat(candidate) then
      return candidate
    end
  end
  return nil
end

--- Compile + run the current file on its own.
---@param opts? { args?: string, stdin?: string }
function M.run_single(opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(source_buf())
  local stdin = opts.stdin or default_stdin(file)
  M.compile_single(function(bin)
    local title = vim.fs.basename(bin)
    if opts.args and opts.args ~= "" then
      title = title .. " " .. opts.args
    end
    if stdin then
      title = title .. " < " .. vim.fs.basename(stdin)
    end
    terminal(launch_cmd(bin, opts.args, stdin), {
      cwd = vim.fs.dirname(file),
      title = title,
      env = run_env(),
    })
  end)
end

-- ---------------------------------------------------------------------------
-- 6. CMake — configure, discover targets via the File API, build, run
-- ---------------------------------------------------------------------------
local function read_json(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local data = fd:read("*a")
  fd:close()
  local ok, decoded = pcall(vim.json.decode, data)
  return ok and decoded or nil
end

--- Ask CMake to emit a codemodel on the next *generate* (the query is an empty
--- file whose name is the request; it must exist before cmake runs).
--- https://cmake.org/cmake/help/latest/manual/cmake-file-api.7.html
local function write_query(build)
  local dir = build .. "/.cmake/api/v1/query/client-nvim"
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/codemodel-v2"
  if not uv.fs_stat(path) then
    local f = io.open(path, "w")
    if f then
      f:close()
    end
  end
end

--- A build dir is only usable once the generator has written its build file —
--- a *failed* generate still leaves CMakeCache.txt behind.
local function is_configured(build)
  return uv.fs_stat(build .. "/CMakeCache.txt") ~= nil
    and (uv.fs_stat(build .. "/Makefile") ~= nil or uv.fs_stat(build .. "/build.ninja") ~= nil)
end

--- Read one CMake cache entry, e.g. cache_value(build, "CMAKE_BUILD_TYPE").
---@return string|nil
local function cache_value(build, key)
  local fd = io.open(build .. "/CMakeCache.txt", "r")
  if not fd then
    return nil
  end
  local pattern = "^" .. key .. ":[%w_]+=(.*)$"
  for line in fd:lines() do
    local value = line:match(pattern)
    if value then
      fd:close()
      return value
    end
  end
  fd:close()
  return nil
end

--- Does the configured build dir still match the current settings? Toggling
--- Debug/Release or sanitizers has to re-run the generate step, otherwise
--- `cmake --build` happily rebuilds with the flags baked in last time.
--- Sanitizer state is tracked through our *own* cache variable rather than by
--- sniffing CMAKE_CXX_FLAGS, so we only ever undo a change we made ourselves.
local function needs_reconfigure(build)
  if (cache_value(build, "CMAKE_BUILD_TYPE") or "") ~= M.settings.build_type then
    return true
  end
  return (cache_value(build, "CUTE_CC_SANITIZE") == "ON") ~= M.settings.sanitize
end

--- Every executable CMake knows how to build: { { name, path } … }.
---@return table[]
function M.targets(buf)
  local build = M.build_dir(buf)
  local reply = build .. "/.cmake/api/v1/reply"
  local indices = {}
  if uv.fs_stat(reply) then
    for name, kind in vim.fs.dir(reply) do
      if kind == "file" and name:match("^index%-.*%.json$") then
        indices[#indices + 1] = name
      end
    end
  end
  -- index-<date>-<hash>.json — the newest sorts last (CMake guarantees this).
  table.sort(indices)
  local index = indices[#indices] and (reply .. "/" .. indices[#indices]) or nil
  local out = {}
  local idx = index and read_json(index)
  local codemodel
  for _, obj in ipairs(idx and idx.objects or {}) do
    if obj.kind == "codemodel" then
      codemodel = read_json(reply .. "/" .. obj.jsonFile)
    end
  end
  -- Every config is accepted: with no CMAKE_BUILD_TYPE, CMake names it "".
  local top = (codemodel and codemodel.paths and codemodel.paths.build) or build
  for _, config in ipairs(codemodel and codemodel.configurations or {}) do
    for _, target in ipairs(config.targets or {}) do
      -- The codemodel's target stubs carry no `type`, so each has to be opened.
      local detail = read_json(reply .. "/" .. target.jsonFile)
      if detail and detail.type == "EXECUTABLE" then
        local artifact = detail.artifacts and detail.artifacts[1] and detail.artifacts[1].path
        if artifact then
          -- artifacts[].path is relative to the *top-level* build dir (and
          -- already honours RUNTIME_OUTPUT_DIRECTORY) — never to target.paths.
          out[#out + 1] = {
            name = detail.name,
            path = artifact:sub(1, 1) == "/" and artifact or (top .. "/" .. artifact),
          }
        end
      end
    end
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

--- Configure (or re-configure) the CMake project. `done` runs on success.
---@param done? fun()
function M.configure(done)
  local root, build = M.root(), M.build_dir()
  if not uv.fs_stat(root .. "/CMakeLists.txt") then
    vim.notify("No CMakeLists.txt above " .. vim.fs.basename(bufpath()), vim.log.levels.WARN)
    return
  end
  write_query(build)
  local argv = {
    "cmake",
    "-S",
    root,
    "-B",
    build,
    "-DCMAKE_BUILD_TYPE=" .. M.settings.build_type,
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
    -- forced color would put ANSI escapes inside the quickfix filenames
    "-DCMAKE_COLOR_DIAGNOSTICS=OFF",
  }
  -- Sanitizers have to reach both the compile and the link step. CUTE_CC_SANITIZE
  -- is our own marker: turning them back off only clears the flag variables when
  -- *we* were the ones who set them, so a project's own flags are never wiped.
  local was_sanitized = cache_value(build, "CUTE_CC_SANITIZE") == "ON"
  if M.settings.sanitize then
    local san = "-fsanitize=address,undefined -fno-sanitize-recover=undefined -fno-omit-frame-pointer -g"
    vim.list_extend(argv, {
      "-DCUTE_CC_SANITIZE=ON",
      "-DCMAKE_CXX_FLAGS=" .. san,
      "-DCMAKE_C_FLAGS=" .. san,
      "-DCMAKE_EXE_LINKER_FLAGS=-fsanitize=address,undefined",
    })
  else
    argv[#argv + 1] = "-DCUTE_CC_SANITIZE=OFF"
    if was_sanitized then
      vim.list_extend(argv, { "-UCMAKE_CXX_FLAGS", "-UCMAKE_C_FLAGS", "-UCMAKE_EXE_LINKER_FLAGS" })
    end
  end
  if vim.fn.executable("ninja") == 1 then
    vim.list_extend(argv, { "-G", "Ninja" })
  end
  echo("  cmake configure (" .. M.settings.build_type .. ") …")
  vim.system(argv, { text = true, cwd = root }, function(res)
    vim.schedule(function()
      if failed(res) then
        to_quickfix(split_output(res), "cmake configure")
        vim.notify("cmake configure failed", vim.log.levels.ERROR)
        M.quickfix()
        return
      end
      -- clangd probes each ancestor dir and its `build/` subdir, so the default
      -- layout needs nothing. For any other build dir name, link the compilation
      -- database into the root so clangd can still find it.
      if M.settings.build_dir ~= "build" then
        local link, generated = root .. "/compile_commands.json", build .. "/compile_commands.json"
        if uv.fs_stat(generated) and not uv.fs_stat(link) then
          uv.fs_symlink(generated, link)
        end
      end
      vim.notify("cmake: configured " .. vim.fs.basename(build), vim.log.levels.INFO)
      if done then
        done()
      end
    end)
  end)
end

--- Build the project (configuring first if needed). `done` runs on success.
--- `target` narrows the build — that's what the run/debug path does, so the inner
--- loop only rebuilds what it is about to launch. <leader>rb passes nothing and
--- builds everything, so errors anywhere in the project still surface.
---@param done? fun()
---@param target? string
---@param reconfigured? boolean  internal: guards against a configure/build loop
function M.build_cmake(done, target, reconfigured)
  local build = M.build_dir()
  if not reconfigured and (not is_configured(build) or needs_reconfigure(build)) then
    M.configure(function()
      M.build_cmake(done, target, true)
    end)
    return
  end
  local argv = { "cmake", "--build", build, "-j", tostring(M.settings.jobs) }
  if target then
    vim.list_extend(argv, { "--target", target })
  end
  echo(vim.trim("  cmake --build " .. (target and ("--target " .. target) or "")) .. " …")
  vim.system(argv, { text = true, cwd = M.root() }, function(res)
    vim.schedule(function()
      finish_build(res, "cmake build", done, M.root())
    end)
  end)
end

--- Ask, unless there's only one answer or the project already has a choice.
--- `force` re-asks even when a target is remembered (that's <leader>rp).
local function choose(root, targets, cb, force)
  if #targets == 1 then
    chosen_target[root] = targets[1].name
    return cb(targets[1])
  end
  if not force then
    for _, t in ipairs(targets) do
      if t.name == chosen_target[root] then
        return cb(t)
      end
    end
  end
  vim.ui.select(targets, {
    prompt = "CMake target to run:",
    format_item = function(t)
      return t.name
    end,
  }, function(pick)
    if pick then
      chosen_target[root] = pick.name
      cb(pick)
    end
  end)
end

--- Resolve which executable to run, asking only when it's ambiguous. A build dir
--- configured without our File API query (by hand, by an IDE) has no target
--- reply — a bare `cmake -B <build>` regenerates one, so recover instead of
--- making the user re-configure.
---@param cb fun(target: table)
---@param force? boolean  re-ask even when a target is already remembered
local function pick_target(cb, force)
  local root, build = M.root(), M.build_dir()
  local targets = M.targets()
  if #targets > 0 then
    return choose(root, targets, cb, force)
  end
  if not is_configured(build) then
    vim.notify("Project isn't configured yet — <leader>rg", vim.log.levels.WARN)
    return
  end
  write_query(build)
  echo("  cmake: reading targets …")
  vim.system({ "cmake", "-B", build }, { text = true, cwd = root }, function(res)
    vim.schedule(function()
      local retry = M.targets()
      if #retry == 0 then
        to_quickfix(split_output(res), "cmake targets")
        vim.notify("No executable targets in this project", vim.log.levels.WARN)
        return
      end
      choose(root, retry, cb, force)
    end)
  end)
end

--- Let the user (re)choose the target this project runs.
function M.select_target()
  pick_target(function(target)
    vim.notify("target: " .. target.name, vim.log.levels.INFO)
  end, true)
end

---@param opts? { args?: string, stdin?: string }
function M.run_cmake(opts)
  opts = opts or {}
  M.build_cmake(function()
    pick_target(function(target)
      terminal(launch_cmd(target.path, opts.args, opts.stdin), {
        cwd = M.root(),
        title = vim.trim(target.name .. " " .. (opts.args or "")) .. (opts.stdin and (" < " .. vim.fs.basename(opts.stdin)) or ""),
        env = run_env(),
      })
    end)
  end, chosen_target[M.root()])
end

-- ---------------------------------------------------------------------------
-- 7. Makefile projects
-- ---------------------------------------------------------------------------
local function makefile(root)
  for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile" }) do
    if uv.fs_stat(root .. "/" .. name) then
      return root .. "/" .. name
    end
  end
end

--- Does the Makefile declare this target?
local function has_target(path, target)
  local fd = io.open(path, "r")
  if not fd then
    return false
  end
  for line in fd:lines() do
    if line:match("^" .. target .. "%s*:") then
      fd:close()
      return true
    end
  end
  fd:close()
  return false
end

---@param done? fun()
function M.build_make(done)
  local root = M.root()
  local target = chosen_target[root]
  local argv = { "make", "-C", root, "-j", tostring(M.settings.jobs) }
  if target then
    argv[#argv + 1] = target
  end
  echo(vim.trim("  make " .. (target or "")) .. " …")
  vim.system(argv, { text = true, cwd = root }, function(res)
    vim.schedule(function()
      finish_build(res, "make", done, root)
    end)
  end)
end

-- Extensions that are never the thing you want to run, even when the exec bit
-- happens to be set (build scripts, sources, libraries, notes).
local NOT_A_BINARY = {
  c = true, cc = true, cpp = true, cxx = true, h = true, hpp = true, hh = true, hxx = true,
  o = true, a = true, so = true, dylib = true, d = true, mk = true, cmake = true,
  sh = true, bash = true, zsh = true, py = true, pl = true, txt = true, md = true,
  json = true, yml = true, yaml = true, toml = true, log = true, ["in"] = true,
}

--- Executable files sitting in the project root — where a Makefile usually
--- drops its binary.
local function root_executables(root)
  local out = {}
  for name, kind in vim.fs.dir(root) do
    local path = root .. "/" .. name
    local ext = name:match("%.([%w+]+)$")
    if kind == "file" and not NOT_A_BINARY[ext] and vim.fn.executable(path) == 1 then
      out[#out + 1] = { name = name, path = path }
    end
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out
end

---@param opts? { args?: string, stdin?: string }
function M.run_make(opts)
  opts = opts or {}
  local root = M.root()
  local mk = makefile(root)
  -- A `run:` rule is the project's own opinion about how to run — prefer it.
  -- It owns the argv, so args/stdin can't be threaded through it.
  if mk and has_target(mk, "run") then
    if (opts.args and opts.args ~= "") or opts.stdin then
      vim.notify("`make run` owns the command line — args/stdin ignored", vim.log.levels.WARN)
    end
    terminal({ "make", "-C", root, "run" }, { cwd = root, title = "make run" })
    return
  end
  M.build_make(function()
    local bins = root_executables(root)
    if #bins == 0 then
      vim.notify("Built, but no executable found in " .. root, vim.log.levels.WARN)
      return
    end
    local function launch(bin)
      terminal(launch_cmd(bin.path, opts.args, opts.stdin), {
        cwd = root,
        title = vim.trim(bin.name .. " " .. (opts.args or "")) .. (opts.stdin and (" < " .. vim.fs.basename(opts.stdin)) or ""),
        env = run_env(),
      })
    end
    if #bins == 1 then
      return launch(bins[1])
    end
    vim.ui.select(bins, {
      prompt = "Binary to run:",
      format_item = function(b)
        return b.name
      end,
    }, function(choice)
      if choice then
        launch(choice)
      end
    end)
  end)
end

-- ---------------------------------------------------------------------------
-- 8. Dispatch — one key, right thing
-- ---------------------------------------------------------------------------
---@param opts? { args?: string, stdin?: string }
function M.run(opts)
  local kind = M.kind()
  if kind == "cmake" then
    M.run_cmake(opts)
  elseif kind == "make" then
    M.run_make(opts)
  else
    M.run_single(opts)
  end
end

function M.build(done)
  local kind = M.kind()
  if kind == "cmake" then
    M.build_cmake(done)
  elseif kind == "make" then
    M.build_make(done)
  else
    M.compile_single(done or function(bin)
      echo("  built " .. vim.fs.basename(bin))
    end)
  end
end

function M.run_with_args()
  vim.ui.input({ prompt = "run args: " }, function(args)
    if args ~= nil then
      M.run({ args = args })
    end
  end)
end

function M.run_with_stdin()
  local file = vim.api.nvim_buf_get_name(source_buf())
  vim.ui.input({ prompt = "stdin file: ", default = default_stdin(file) or "", completion = "file" }, function(path)
    if path and path ~= "" then
      if not uv.fs_stat(path) then
        vim.notify("No such file: " .. path, vim.log.levels.ERROR)
        return
      end
      M.run({ stdin = path })
    end
  end)
end

--- Build with debug info, then hand the binary to nvim-dap / lldb-dap.
function M.debug()
  -- A Release build has no symbols to step through, so switch (and say so).
  if M.settings.build_type ~= "Debug" then
    M.settings.build_type = "Debug"
    vim.notify("switched to a Debug build (-g) for the debugger", vim.log.levels.INFO)
  end
  local function launch(program, cwd)
    local ok, dap = pcall(require, "dap")
    if not ok then
      vim.notify("nvim-dap is not loaded", vim.log.levels.ERROR)
      return
    end
    dap.run({
      name = "Launch " .. vim.fs.basename(program),
      type = "lldb",
      request = "launch",
      program = program,
      cwd = cwd,
      stopOnEntry = false,
      args = {},
    })
  end
  if M.kind() == "cmake" then
    M.build_cmake(function()
      pick_target(function(target)
        launch(target.path, M.root())
      end)
    end, chosen_target[M.root()])
  elseif M.kind() == "make" then
    M.build_make(function()
      local bins = root_executables(M.root())
      if #bins == 0 then
        vim.notify("No executable found to debug", vim.log.levels.WARN)
        return
      end
      launch(bins[1].path, M.root())
    end)
  else
    local file = vim.api.nvim_buf_get_name(source_buf())
    M.compile_single(function(bin)
      launch(bin, vim.fs.dirname(file))
    end)
  end
end

--- Escape a literal test name for ctest's -R regex.
local function re_escape(name)
  return (name:gsub("[%^%$%.%[%]%*%+%-%?%(%)%{%}|\\]", "\\%0"))
end

--- ctest for CMake projects (`filter` is a -R regex).
---@param filter? string
function M.test(filter)
  local build = M.build_dir()
  if not is_configured(build) then
    vim.notify("No configured CMake build dir — <leader>rg first", vim.log.levels.WARN)
    return
  end
  local cmd = { "ctest", "--test-dir", build, "--output-on-failure" }
  if filter and filter ~= "" then
    vim.list_extend(cmd, { "-R", filter })
  end
  terminal(cmd, { cwd = M.root(), title = vim.trim("ctest " .. (filter and ("-R " .. filter) or "")) })
end

--- Pick one registered test by name (ctest knows them all) and run just that.
--- Falls back to a plain -R prompt when the project has no test list.
function M.test_pick()
  local build = M.build_dir()
  if not is_configured(build) then
    vim.notify("No configured CMake build dir — <leader>rg first", vim.log.levels.WARN)
    return
  end
  vim.system(
    { "ctest", "--test-dir", build, "--show-only=json-v1" },
    { text = true },
    vim.schedule_wrap(function(res)
      local ok, decoded = pcall(vim.json.decode, res.stdout or "")
      local names = {}
      for _, t in ipairs(ok and decoded.tests or {}) do
        names[#names + 1] = t.name
      end
      if #names == 0 then
        vim.ui.input({ prompt = "ctest -R (regex): " }, function(re)
          if re and re ~= "" then
            M.test(re)
          end
        end)
        return
      end
      vim.ui.select(names, { prompt = "ctest:" }, function(pick)
        if pick then
          M.test("^" .. re_escape(pick) .. "$")
        end
      end)
    end)
  )
end

--- Remove build products. Only ever asks the build system to clean itself, or
--- deletes this file's cached binary — it never rm -rf's a directory.
function M.clean()
  local kind = M.kind()
  if kind == "cmake" and is_configured(M.build_dir()) then
    vim.system({ "cmake", "--build", M.build_dir(), "--target", "clean" }, { text = true }, function(res)
      vim.schedule(function()
        vim.notify(res.code == 0 and "cmake: cleaned" or "clean failed", res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      end)
    end)
  elseif kind == "make" then
    local mk = makefile(M.root())
    if mk and has_target(mk, "clean") then
      vim.system({ "make", "-C", M.root(), "clean" }, { text = true }, function()
        vim.schedule(function()
          vim.notify("make: cleaned", vim.log.levels.INFO)
        end)
      end)
    else
      vim.notify("Makefile has no `clean` target", vim.log.levels.WARN)
    end
  else
    local file = vim.api.nvim_buf_get_name(source_buf())
    if file ~= "" then
      local bin = cache_bin(file)
      -- `clang -g` also drops a <bin>.dSYM bundle (the executable itself carries
      -- no DWARF); both live under stdpath("cache"), never in the source tree.
      local removed = false
      if uv.fs_stat(bin) then
        uv.fs_unlink(bin)
        removed = true
      end
      if uv.fs_stat(bin .. ".dSYM") then
        vim.fn.delete(bin .. ".dSYM", "rf")
        removed = true
      end
      vim.notify(removed and ("removed " .. bin) or "nothing to clean", vim.log.levels.INFO)
    end
  end
end

-- ---------------------------------------------------------------------------
-- 9. Toggles + info
-- ---------------------------------------------------------------------------
function M.toggle_sanitize()
  M.settings.sanitize = not M.settings.sanitize
  vim.notify("sanitizers (asan+ubsan): " .. (M.settings.sanitize and "ON" or "OFF"), vim.log.levels.INFO)
end

function M.toggle_build_type()
  M.settings.build_type = M.settings.build_type == "Debug" and "Release" or "Debug"
  vim.notify("build type: " .. M.settings.build_type, vim.log.levels.INFO)
end

function M.pick_std()
  local is_c = vim.bo[source_buf()].filetype == "c"
  local options = is_c and { "c11", "c17", "c23" } or { "c++17", "c++20", "c++23", "c++26" }
  vim.ui.select(options, { prompt = (is_c and "C" or "C++") .. " standard:" }, function(choice)
    if choice then
      M.settings.std[is_c and "c" or "cpp"] = choice
      vim.notify("-std=" .. choice, vim.log.levels.INFO)
    end
  end)
end

--- What the next build will do, and where things live.
function M.info()
  local kind, ft = M.kind(), vim.bo[source_buf()].filetype
  local lines = {
    "mode        " .. kind,
    "root        " .. M.root(),
    "compiler    " .. (M.tool(ft == "c" and "clang" or "clang++") or "not found"),
    "standard    -std=" .. (ft == "c" and M.settings.std.c or M.settings.std.cpp),
    "build type  " .. M.settings.build_type,
    "sanitizers  " .. (M.settings.sanitize and "address,undefined" or "off"),
    "warnings    " .. table.concat(M.settings.warnings, " "),
  }
  if kind == "cmake" then
    lines[#lines + 1] = "build dir   " .. M.build_dir()
    lines[#lines + 1] = "target      " .. (chosen_target[M.root()] or "(auto)")
  elseif kind == "single" then
    local file = vim.api.nvim_buf_get_name(source_buf())
    if file ~= "" then
      lines[#lines + 1] = "binary      " .. cache_bin(file)
      lines[#lines + 1] = "stdin       " .. (default_stdin(file) or "(none)")
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "C/C++ build" })
end

--- Write a project-local `.clangd`, which is the one file that can teach clangd
--- everything at once: the language standard per extension (a single
--- `-std=c++23` would make clangd reject every .c file), which clang-tidy checks
--- to run (with no config, *zero* checks fire even though --clang-tidy is on),
--- and that IncludeCleaner should stop flagging half-written includes.
--- A compile_commands.json, when present, still wins for compile flags.
function M.write_clangd_config()
  local path = M.root() .. "/.clangd"
  local content = ([[
# Written by lua/config/cc.lua (<leader>rn / :CcClangd). Safe to edit or delete.
# A compile_commands.json takes precedence over CompileFlags below.
CompileFlags:
  Add: [%s]
---
If:
  PathMatch: ['.*\.(cpp|cxx|cc|hpp|hxx|hh|h|ipp|tpp|inl)']
CompileFlags:
  Add: [-xc++, -std=%s]
---
If:
  PathMatch: ['.*\.c']
CompileFlags:
  Add: [-std=%s]
---
Diagnostics:
  # off by default they are noisy while a file is still being written
  UnusedIncludes: None
  MissingIncludes: None
  ClangTidy:
    # clangd runs these in-process; the clang-tidy *binary* is not needed.
    # (clang-analyzer-* is pointless here — clangd never runs the path-sensitive
    # analyzer.) modernize-* checks arrive as HINTs, everything else as warnings.
    Add: [bugprone-*, performance-*, modernize-*, readability-*]
    Remove:
      [
        modernize-use-trailing-return-type,
        readability-identifier-length,
        readability-magic-numbers,
      ]
]]):format(table.concat(M.settings.warnings, ", "), M.settings.std.cpp, M.settings.std.c)

  local function write()
    local fd = io.open(path, "w")
    if not fd then
      vim.notify("cannot write " .. path, vim.log.levels.ERROR)
      return
    end
    fd:write(content)
    fd:close()
    vim.notify("wrote " .. path .. " — `:lsp restart` to pick it up", vim.log.levels.INFO)
  end
  if uv.fs_stat(path) then
    vim.ui.select({ "keep", "overwrite" }, { prompt = ".clangd exists:" }, function(choice)
      if choice == "overwrite" then
        write()
      end
    end)
  else
    write()
  end
end

--- Scaffold a CMakeLists.txt for the current directory — the bridge from
--- "one scratch file" to "a project with several translation units".
function M.init_project()
  local dir = bufdir()
  local path = dir .. "/CMakeLists.txt"
  if uv.fs_stat(path) then
    vim.notify("CMakeLists.txt already exists", vim.log.levels.WARN)
    return
  end
  local name = vim.fs.basename(dir):gsub("[^%w_]", "_")
  local std = M.settings.std.cpp:gsub("c%+%+", "")
  local content = ([[
cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES CXX)

set(CMAKE_CXX_STANDARD %s)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

file(GLOB SOURCES CONFIGURE_DEPENDS *.cpp *.cc *.cxx)
add_executable(%s ${SOURCES})
target_compile_options(%s PRIVATE -Wall -Wextra -Wpedantic)

# enable_testing()
# add_test(NAME smoke COMMAND %s)
]]):format(name, std, name, name, name)
  local fd = io.open(path, "w")
  if not fd then
    vim.notify("cannot write " .. path, vim.log.levels.ERROR)
    return
  end
  fd:write(content)
  fd:close()
  -- clangd's --background-index persists to <root>/.cache/clangd, and the build
  -- dir is generated: neither belongs in git.
  local ignore = dir .. "/.gitignore"
  if not uv.fs_stat(ignore) then
    local gi = io.open(ignore, "w")
    if gi then
      gi:write(M.settings.build_dir .. "/\n.cache/\ncompile_commands.json\n")
      gi:close()
    end
  end
  vim.notify("wrote " .. path .. " — <leader>rg to configure", vim.log.levels.INFO)
end

-- ---------------------------------------------------------------------------
-- 10. Filetype detection
-- ---------------------------------------------------------------------------
-- Neovim already resolves .hpp/.hh/.hxx/.ipp/.inl/.cc/.cxx to cpp and .cu/.cuh
-- to cuda, and it treats a bare `.h` as **C++** unless it smells of Objective-C.
-- That C++-first default is wrong in a C project, where a .h read as cpp gets
-- the wrong treesitter parser and the wrong clangd language id. So sniff the
-- contents. Note this REPLACES Neovim's builtin `h` entry — returning nil does
-- not fall back to it (the file would end up detected as `conf`), hence the
-- explicit delegation for empty buffers.
local CXX_MARKERS = {
  "^%s*template%s*<",
  "^%s*namespace[%s{]",
  "^%s*class%s+[%w_]",
  "^%s*struct%s+[%w_]+%s*:",
  "^%s*public%s*:",
  "^%s*private%s*:",
  "^%s*protected%s*:",
  "^%s*using%s+namespace%s",
  "^%s*using%s+[%w_]+%s*=",
  "^%s*#%s*include%s*<[%w_/]+>", -- extensionless C++ header: <string>
  '^%s*extern%s+"C"',
  "^%s*virtual%s",
  "^%s*explicit%s",
  "^%s*constexpr%s",
  "^%s*friend%s",
  "^%s*static_assert%s*%(",
  "%f[%w]nullptr%f[^%w]",
  "%f[%w]std%s*::",
  "[%w_]%s*::%s*[%w_~]",
}

vim.filetype.add({
  extension = {
    h = function(path, bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)
      -- Nothing but blanks and include-guard boilerplate (which is exactly what
      -- a brand-new file scaffolded by the BufNewFile template holds) carries no
      -- evidence either way — let Neovim decide, which means cpp.
      local evidence = false
      for _, line in ipairs(lines) do
        local t = vim.trim(line)
        if
          t ~= ""
          and not t:find("^#%s*pragma once")
          and not t:find("^#%s*ifndef")
          and not t:find("^#%s*define%s+[%w_]+%s*$")
          and not t:find("^#%s*endif")
          and not t:find("^//")
        then
          evidence = true
          break
        end
      end
      if not evidence then
        return require("vim.filetype.detect").header(path, bufnr)
      end
      for _, line in ipairs(lines) do
        if line:find("^@interface") or line:find("^@end") or line:find("^@class") then
          return vim.g.c_syntax_for_h and "objc" or "objcpp"
        end
      end
      for _, line in ipairs(lines) do
        if not line:find("^%s*//") then
          for _, pattern in ipairs(CXX_MARKERS) do
            if line:find(pattern) then
              return "cpp"
            end
          end
        end
      end
      return "c"
    end,
    tpp = "cpp", -- Neovim maps .tpp to the unrelated `tpp` presentation filetype
  },
  filename = {
    [".clang-format"] = "yaml",
    [".clang-tidy"] = "yaml",
    [".clangd"] = "yaml",
  },
})

-- ---------------------------------------------------------------------------
-- 11. Buffer-local setup: options, templates, keymaps
-- ---------------------------------------------------------------------------
local group = vim.api.nvim_create_augroup("cute_cc", { clear = true })

-- Remember the C-family buffer being edited, so a build started while the run
-- terminal or the quickfix list is focused still resolves the right project.
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  desc = "Track the current C/C++ source buffer",
  callback = function(ev)
    if SOURCE_FT[vim.bo[ev.buf].filetype] then
      last_source = ev.buf
    end
  end,
})

-- New files start from something that compiles. `vim.g.cute_cc_templates = false`
-- turns it off. Keyed on the extension, not the filetype: BufNewFile can fire
-- before filetype detection has run.
vim.api.nvim_create_autocmd("BufNewFile", {
  group = group,
  pattern = { "*.c", "*.cpp", "*.cc", "*.cxx", "*.h", "*.hpp", "*.hh", "*.hxx" },
  desc = "Scaffold new C/C++ files",
  callback = function(ev)
    if vim.g.cute_cc_templates == false then
      return
    end
    local ext = vim.fn.fnamemodify(ev.file, ":e")
    local pad = string.rep(" ", M.settings.indent)
    local lines
    if ext:match("^h") then
      lines = { "#pragma once", "" }
    elseif ext == "c" then
      lines = { "#include <stdio.h>", "", "int main(void) {", pad, pad .. "return 0;", "}" }
    else
      lines = { "#include <iostream>", "", "int main() {", pad, pad .. "return 0;", "}" }
    end
    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { #lines > 2 and 4 or 2, #pad })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "c", "cpp", "cuda", "objc", "objcpp" },
  desc = "C/C++ buffer options + build keymaps",
  callback = function(ev)
    local buf = ev.buf

    -- Indent with Neovim's built-in C engine rather than treesitter's. Two
    -- reasons: nvim-treesitter's C/C++ indent is still experimental, and a
    -- non-empty 'indentexpr' *overrules* 'cindent', so leaving the treesitter
    -- one in place would win. The tuned 'cinoptions' fixes what stock cindent
    -- gets wrong in C++ (namespaces, access specifiers, `case X: {` blocks,
    -- lambdas). Applied twice: autocmds fire in registration order and this
    -- module is loaded before lazy.nvim, so the scheduled pass is what actually
    -- lands after the treesitter FileType autocmd.
    local function indent()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local bo = vim.bo[buf]
      bo.indentexpr = ""
      bo.cindent = true
      bo.shiftwidth = M.settings.indent
      bo.tabstop = M.settings.indent
      bo.softtabstop = M.settings.indent
      bo.expandtab = true
      --  g0.5s  access specifiers at half a shiftwidth      N-s  no namespace indent
      --  h0.5s  statements after them back a full one       E-s  no extern "C" indent
      --  l1     align a `case X: {` block with its label     j1,J1  lambdas / brace init
      --  (0     continuation aligns under the open paren     W1s  …unless it's last
      --  m1     a leading `)` lines up with its opener       is   base-class lists
      -- (k1s is deliberately absent: it de-aligns multi-line if/while conditions.)
      bo.cinoptions = "g0.5s,h0.5s,N-s,E-s,:1s,=1s,l1,j1,J1,(0,W1s,m1,+1s,is"
    end
    indent()
    vim.schedule(indent)

    local bo, o = vim.bo[buf], vim.opt_local
    o.colorcolumn = tostring(M.settings.column)
    bo.commentstring = "// %s"
    -- `:make` runs the same command and error parsing as <leader>rb.
    bo.errorformat = M.errorformat
    local kind = M.kind(buf)
    if kind == "cmake" then
      bo.makeprg = "cmake --build " .. vim.fn.fnameescape(M.build_dir(buf)) .. " -j " .. M.settings.jobs
    elseif kind == "make" then
      bo.makeprg = "make -C " .. vim.fn.fnameescape(M.root(buf)) .. " -j " .. M.settings.jobs
    else
      local file = vim.api.nvim_buf_get_name(buf)
      if file ~= "" and SOURCE_FT[vim.bo[buf].filetype] then
        local parts = {}
        for _, a in ipairs(compile_argv(file, vim.bo[buf].filetype, cache_bin(file, true))) do
          parts[#parts + 1] = vim.fn.fnameescape(a) -- escapes spaces, and % / # (which :make would expand)
        end
        bo.makeprg = table.concat(parts, " ")
      end
    end

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end
    -- run / build — <leader>r
    map("<leader>rr", function() M.run() end, "Build & run")
    map("<leader>rs", function() M.run_single() end, "Build & run this file alone")
    map("<leader>rb", function() M.build() end, "Build only")
    map("<leader>rR", M.run_with_args, "Build & run with args…")
    map("<leader>ri", M.run_with_stdin, "Build & run with stdin file…")
    map("<leader>rl", M.rerun, "Re-run last command")
    map("<leader>rg", function() M.configure() end, "CMake configure (generate)")
    map("<leader>rp", M.select_target, "Pick CMake target")
    map("<leader>rc", M.clean, "Clean build products")
    map("<leader>rz", M.toggle_sanitize, "Toggle sanitizers (asan+ubsan)")
    map("<leader>ro", M.toggle_build_type, "Toggle Debug / Release")
    map("<leader>rv", M.pick_std, "Select language standard")
    map("<leader>rq", M.quickfix, "Build errors (quickfix)")
    map("<leader>rf", M.info, "Show build settings")
    map("<leader>rn", M.write_clangd_config, "Write a .clangd (std + tidy)")
    map("<leader>rP", M.init_project, "Scaffold a CMakeLists.txt")
    -- test — ctest (neotest has no C/C++ adapter here)
    map("<leader>tt", function() M.test() end, "ctest (all)")
    map("<leader>tf", M.test_pick, "ctest — pick a test")
    -- debug — build with -g, then lldb-dap
    map("<leader>dR", M.debug, "Build & debug (lldb)")
  end,
})

-- ---------------------------------------------------------------------------
-- 12. Commands (scriptable equivalents of the keymaps)
-- ---------------------------------------------------------------------------
local command = vim.api.nvim_create_user_command
command("CcRun", function(a)
  M.run({ args = a.args })
end, { nargs = "*", desc = "Build & run (C/C++)" })
command("CcBuild", function()
  M.build()
end, { desc = "Build (C/C++)" })
command("CcDebug", M.debug, { desc = "Build & debug with lldb (C/C++)" })
command("CcTest", function(a)
  M.test(a.args)
end, { nargs = "?", desc = "ctest [-R regex]" })
command("CcConfigure", function()
  M.configure()
end, { desc = "cmake configure + compile_commands.json" })
command("CcClean", M.clean, { desc = "Clean build products (C/C++)" })
command("CcInfo", M.info, { desc = "Show the C/C++ build settings" })
command("CcClangd", M.write_clangd_config, { desc = "Write a project .clangd (std + clang-tidy)" })
command("CcInit", M.init_project, { desc = "Scaffold a CMakeLists.txt here" })

return M
