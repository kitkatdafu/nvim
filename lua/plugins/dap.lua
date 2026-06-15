-- Debugging — nvim-dap + dap-python (debugpy), with a UI and inline values.
-- uv: the debuggee runs under the project's `.venv` python, so install debugpy
-- there:  uv add --dev debugpy   (see README → "Debugging").
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
