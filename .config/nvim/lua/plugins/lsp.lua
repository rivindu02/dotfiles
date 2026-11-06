return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "SmiteshP/nvim-navic",
            "aznhe21/actions-preview.nvim",
        },
        config = function()
            local project = require("core.project")
            local navic = require("nvim-navic")
            navic.setup({ highlight = true, separator = "  ", depth_limit = 5 })
            require("actions-preview").setup()
            require("mason").setup()

            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                signs = true,
                underline = true,
                update_in_insert = false,
            })

            local group = vim.api.nvim_create_augroup("UserLsp", { clear = true })
            vim.api.nvim_create_autocmd("LspAttach", {
                group = group,
                callback = function(event)
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if not client then return end
                    local function map(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
                    end
                    map("gd", vim.lsp.buf.definition, "Go to definition")
                    map("gr", vim.lsp.buf.references, "Find references")
                    map("gi", vim.lsp.buf.implementation, "Go to implementation")
                    map("K", vim.lsp.buf.hover, "Hover documentation")
                    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                    map("[g", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
                    map("]g", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
                    vim.keymap.set({ "n", "v" }, "<leader>ca", require("actions-preview").code_actions,
                        { buffer = event.buf, desc = "Code actions" })

                    if client:supports_method("textDocument/documentSymbol") then
                        navic.attach(client, event.buf)
                    end
                    if client:supports_method("textDocument/inlayHint") then
                        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
                    end
                end,
            })

            -- Neovim 0.11+ API: Mason 2 no longer supports setup handlers.
            vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
            local function python_root(bufnr, on_dir)
                local path = vim.api.nvim_buf_get_name(bufnr)
                -- Give standalone scripts a workspace too, without requiring Git/pyproject.
                on_dir(vim.fs.root(path, {
                    "pyrightconfig.json", "pyproject.toml", "ruff.toml", ".ruff.toml",
                    "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "package.xml", ".git",
                }) or project.directory(path))
            end
            vim.lsp.config("pyright", {
                root_dir = python_root,
                before_init = function(_, config)
                    config.settings.python.pythonPath = project.python(config.root_dir)
                end,
                settings = {
                    pyright = { disableOrganizeImports = true }, -- Ruff owns import actions.
                    python = { analysis = { diagnosticMode = "openFilesOnly" } },
                },
            })
            vim.lsp.config("ruff", {
                root_dir = python_root,
                on_attach = function(client)
                    client.server_capabilities.hoverProvider = false -- Pyright supplies hover.
                    client.server_capabilities.documentFormattingProvider = false -- Black formats Python.
                    client.server_capabilities.documentRangeFormattingProvider = false
                end,
            })
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--background-index", "--completion-style=detailed", "--header-insertion=never" },
                root_dir = function(bufnr, on_dir)
                    local path = vim.api.nvim_buf_get_name(bufnr)
                    on_dir(project.ros_root(path) or vim.fs.root(path,
                        { ".clangd", "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git" })
                        or vim.fs.dirname(path))
                end,
            })
            vim.lsp.config("neocmake", {
                root_markers = { ".neocmake.toml", "CMakePresets.json", "CMakeLists.txt", ".git" },
            })
            vim.lsp.config("lua_ls", {
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })

            local servers = { "pyright", "ruff", "clangd", "neocmake", "yamlls", "bashls", "lua_ls", "ts_ls" }
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_enable = false, -- Old installed Java/Solidity servers stay inactive.
            })
            vim.lsp.enable(servers)
        end,
    },
}
