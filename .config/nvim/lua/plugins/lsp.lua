-- LSP Core
return {
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v3.x",
        dependencies = {
            "neovim/nvim-lspconfig",
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",       -- keep this one; lsp-zero needs it for capabilities
            "SmiteshP/nvim-navic",
            "aznhe21/actions-preview.nvim",
            "mfussenegger/nvim-jdtls",
        },
        config = function()

            -- -----------------------
            -- NAVIC BREADCRUMBS
            -- -----------------------
            local navic = require("nvim-navic")
            navic.setup({ highlight = true, separator = "  ", depth_limit = 5 })

            -- -----------------------
            -- LSP-ZERO ON_ATTACH
            -- -----------------------
            local lsp_zero = require('lsp-zero')

            lsp_zero.on_attach(function(client, bufnr)
                local opts = { buffer = bufnr }

                -- Navigation
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                --vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)

                -- Hover / signature
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                --vim.keymap.set('n', '<leader>si', vim.lsp.buf.signature_help, opts)

                -- Refactor
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
                -- vim.keymap.set('n', '<leader>qf', function()
                --     vim.lsp.buf.code_action({ apply = true })
                -- end, opts)

                -- Diagnostics
                vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, opts)
                vim.keymap.set('n', ']g', vim.diagnostic.goto_next, opts)

                -- Java (jdtls) specific
                -- if client.name == 'jdtls' then
                --     vim.keymap.set('n', '<leader>jm', function()
                --         require('jdtls').organize_imports()
                --     end, opts)
                --     vim.keymap.set('n', '<leader>ji', function()
                --         require('jdtls').organize_imports()
                --     end, opts)
                --     vim.keymap.set('n', '<leader>jt', function()
                --         require('jdtls').type_hierarchy()
                --     end, opts)
                --     vim.keymap.set('n', '<leader>jr', function()
                --         vim.lsp.stop_client(vim.lsp.get_active_clients())
                --         vim.cmd('edit')
                --     end, opts)
                -- end

                -- 1. Breadcrumbs
                if client.server_capabilities.documentSymbolProvider then
                    navic.attach(client, bufnr)
                end

                -- 2. Inlay hints
                if client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end

                -- 3. Visual code actions
                vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
            end)

            -- Diagnostic display
            vim.diagnostic.config({
                virtual_text = { prefix = '●' },
                signs = true,
                underline = true,
                update_in_insert = false,
            })

            -- -----------------------
            -- MASON
            -- -----------------------
            require('mason').setup()
            require('mason-lspconfig').setup({
                ensure_installed = {
                    'pyright',
                    'clangd',
                    'ts_ls',
                    'bashls',
                    'lua_ls',
                    'jdtls',
                    'solidity_ls_nomicfoundation',
                },
                handlers = {
                    lsp_zero.default_setup,
                    jdtls = lsp_zero.noop,
                },
            })

            -- -----------------------
            -- JDTLS MANUAL SETUP
            -- -----------------------
            local lombok_path = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls/lombok.jar")
            local jdtls_ok, jdtls = pcall(require, 'jdtls')
            if jdtls_ok then
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = "java",
                    callback = function()
                        local workspace = vim.fn.stdpath('data') .. '/jdtls-workspace/' ..
                            vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
                        local config = {
                            cmd = {
                                '/usr/lib/jvm/java-21-openjdk/bin/java',
                                '-Xmx1g',
                                '-javaagent:' .. lombok_path,
                                '-jar', vim.fn.glob(vim.fn.stdpath('data') .. '/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
                                '-configuration', vim.fn.stdpath('data') .. '/mason/packages/jdtls/config_linux',
                                '-data', workspace,
                            },
                            root_dir = vim.fs.dirname(vim.fs.find(
                                { 'pom.xml', 'build.gradle', '.git' },
                                { upward = true }
                            )[1]),
                            settings = {
                                java = {
                                    configuration = {
                                        runtimes = {
                                            {
                                                name = "JavaSE-17",
                                                path = "/usr/lib/jvm/java-17-openjdk/",
                                                default = true,
                                            },
                                            {
                                                name = "JavaSE-21",
                                                path = "/usr/lib/jvm/java-21-openjdk/",
                                            },
                                        },
                                    },
                                },
                            },
                        }
                        jdtls.start_or_attach(config)
                    end,
                })
            end

        end,
    }
}
