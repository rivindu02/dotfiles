return {
    {
        "mfussenegger/nvim-dap",
        keys = {
            { "<F5>", function() require("dap").continue() end, desc = "Debug: continue" },
            { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
            { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
            { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            { "<leader>dt", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
            { "<leader>dB", function()
                require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, desc = "Conditional breakpoint" },
            { "<leader>dc", function() require("dap").continue() end, desc = "Debug: continue" },
            { "<leader>dn", function() require("dap").step_over() end, desc = "Debug: step over" },
            { "<leader>di", function() require("dap").step_into() end, desc = "Debug: step into" },
            { "<leader>do", function() require("dap").step_out() end, desc = "Debug: step out" },
            { "<leader>dq", function() require("dap").terminate() end, desc = "Debug: terminate" },
            { "<leader>dr", function() require("dap").restart() end, desc = "Debug: restart" },
            { "<leader>du", function() require("dapui").toggle() end, desc = "Debug UI" },
            { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Debug: evaluate" },
        },
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "theHamsta/nvim-dap-virtual-text",
            "mfussenegger/nvim-dap-python",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local project = require("core.project")

            dapui.setup()
            require("nvim-dap-virtual-text").setup({ commented = true })
            dap.listeners.before.attach.dapui_config = function() dapui.open() end
            dap.listeners.before.launch.dapui_config = function() dapui.open() end
            dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
            dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

            -- Keep the adapter's environment separate from the program's environment.
            -- Mason exposes a stable executable, independent of its package layout.
            require("dap-python").setup("debugpy-adapter", {
                pythonPath = function() return project.python() end,
            })
            table.insert(dap.configurations.python, {
                name = "Python module (including ROS 2 nodes)",
                type = "python",
                request = "launch",
                module = function() return vim.fn.input("Module (e.g. my_package.my_node): ") end,
                pythonPath = function() return project.python() end,
                cwd = function() return project.root() end,
                console = "integratedTerminal",
            })

            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                executable = { command = "codelldb", args = { "--port", "${port}" } },
            }
            dap.configurations.cpp = {
                {
                    name = "Launch C/C++ executable",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Executable (ROS: install/<pkg>/lib/<pkg>/<node>): ", project.root() .. "/", "file")
                    end,
                    cwd = function() return project.root() end,
                    stopOnEntry = false,
                },
                {
                    name = "Attach to C/C++ process",
                    type = "codelldb",
                    request = "attach",
                    pid = require("dap.utils").pick_process,
                    cwd = function() return project.root() end,
                },
            }
            dap.configurations.c = dap.configurations.cpp
            -- STM32 requires a board-specific GDB/OpenOCD configuration; see README.md.
        end,
    },
}
