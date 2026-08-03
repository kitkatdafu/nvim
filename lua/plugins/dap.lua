-- Debugging — nvim-dap with a UI and inline values.
--   • Python: dap-python (debugpy) under the project's uv `.venv`, so install it
--     there:  uv add --dev debugpy   (see README → "Debugging").
--   • C/C++:  lldb-dap, which the Xcode Command Line Tools already ship (there
--     is no gdb on macOS arm64 and no codesigning/"developer mode" step needed).
--     <leader>dR builds the current file/target with -g and launches it.
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "mfussenegger/nvim-dap-python",
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
    "theHamsta/nvim-dap-virtual-text",
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
    {
      "<leader>dB",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "Conditional breakpoint",
    },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
    { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
    { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dn", function() require("dap-python").test_method() end, desc = "Debug test method" },
    { "<leader>df", function() require("dap-python").test_class() end, desc = "Debug test class" },
    { "<F5>", function() require("dap").continue() end, desc = "Continue" },
    { "<F10>", function() require("dap").step_over() end, desc = "Step over" },
    { "<F11>", function() require("dap").step_into() end, desc = "Step into" },
    { "<F12>", function() require("dap").step_out() end, desc = "Step out" },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    require("nvim-dap-virtual-text").setup({})

    -- debugpy launched with the project's uv venv python.
    local py = require("config.python")
    require("dap-python").setup(py.python())
    require("dap-python").resolve_python = function()
      return py.python()
    end

    -- C/C++ via lldb-dap. A plain stdio ("executable") adapter: the Command Line
    -- Tools' lldb-dap has no --port flag, so the copy-pasteable `type = "server"`
    -- recipes found online cannot work here.
    local lldb = require("config.cc").lldb_dap()
    if lldb then
      dap.adapters.lldb = { type = "executable", command = lldb, name = "lldb" }
      local launch = {
        {
          name = "Launch (lldb)",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          args = {},
          cwd = "${workspaceFolder}",
          env = {},
          stopOnEntry = false,
          -- Must stay false: the runInTerminal launcher *is* the Apple-signed
          -- lldb-dap binary, which macOS will not let the adapter attach to.
          -- The debuggee's stdout still arrives in the dap REPL (<leader>dr);
          -- the trade-off is that it gets no interactive stdin.
          runInTerminal = false,
        },
      }
      dap.configurations.c = launch
      dap.configurations.cpp = launch
      dap.configurations.objc = launch
      dap.configurations.objcpp = launch
      -- Breakpoints need DWARF, which macOS keeps *outside* the executable in a
      -- sibling .dSYM (one-step `clang++ -g` builds one automatically) or in the
      -- original .o files. Delete either and breakpoints silently never bind.
    end

    -- Auto open/close the UI around sessions.
    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

    -- Signs (colors from the cute theme).
    vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition" })
    vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
    vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })
  end,
}
