-- Debugger
return {
    {
        "mfussenegger/nvim-dap",
		keys = { '<F5>', '<F10>', '<F11>', '<leader>db', '<leader>dc' },
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",         -- required by dap-ui
            "theHamsta/nvim-dap-virtual-text",
            -- Language adapters
            "mfussenegger/nvim-dap-python",
            "microsoft/vscode-java-debug",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            -- -----------------------
            -- DAP UI AUTO OPEN/CLOSE
            -- -----------------------
            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end

            dapui.setup()

            -- -----------------------
            -- VIRTUAL TEXT
            -- -----------------------
            require("nvim-dap-virtual-text").setup({
                commented = true,   -- show virtual text alongside comment
            })

            -- -----------------------
            -- PYTHON
            -- -----------------------
            require("dap-python").setup(
                vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
            )

            -- -----------------------
            -- C / C++ (codelldb via mason)
            -- -----------------------
            local codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                executable = {
                    command = codelldb_path,
                    args = { "--port", "${port}" },
                },
            }
            dap.configurations.cpp = {
                {
                    name = "Launch file",
                    type = "codelldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
                },
            }
            dap.configurations.c = dap.configurations.cpp

            -- -----------------------
            -- JAVA (jdtls handles this via nvim-jdtls)
            -- jdtls automatically registers its own DAP adapter
            -- when jdtls attaches, so no manual config needed here.
            -- Trigger with: require('jdtls.dap').setup_dap_main_class_configs()
            -- -----------------------
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "java",
                callback = function()
                    local jdtls_ok, jdtls_dap = pcall(require, "jdtls.dap")
                    if jdtls_ok then
                        jdtls_dap.setup_dap_main_class_configs()
                    end
                end,
            })

            -- -----------------------
            -- KEYMAPS
            -- -----------------------
            local map = vim.keymap.set

            -- Breakpoints
            map("n", "<leader>dt", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
            map("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, { desc = "Conditional Breakpoint" })

            -- Control flow
            map("n", "<leader>dc", dap.continue,          { desc = "Continue" })
            map("n", "<leader>dn", dap.step_over,         { desc = "Step Over" })
            map("n", "<leader>di", dap.step_into,         { desc = "Step Into" })
            map("n", "<leader>do", dap.step_out,          { desc = "Step Out" })
            map("n", "<leader>dq", dap.terminate,         { desc = "Terminate" })
            map("n", "<leader>dr", dap.restart,           { desc = "Restart" })

            -- UI
            map("n", "<leader>du", dapui.toggle,          { desc = "Toggle DAP UI" })
            map("n", "<leader>de", dapui.eval,            { desc = "Eval Expression" })
            map("v", "<leader>de", dapui.eval,            { desc = "Eval Selection" })
        end,
    }
}
