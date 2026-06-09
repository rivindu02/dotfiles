-- Search Infrastructures
return {
    {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
        config = function()
            local builtin = require('telescope.builtin')
            local telescope = require('telescope')
            local open_with_trouble = require("trouble.sources.telescope").open

            telescope.setup({
                defaults = {
                    file_ignore_patterns = { "target/", ".git/", "node_modules/", "%.class" },
                    layout_strategy = 'horizontal',
                    layout_config = {
                        horizontal = {
                            preview_width = 0.55,
                        },
                    },
                    mappings = {
                        i = { ["<C-t>"] = open_with_trouble },
                        n = { ["<C-t>"] = open_with_trouble },
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown {}
                    }
                }
            })

            telescope.load_extension("fzf")
            telescope.load_extension("ui-select")
            telescope.load_extension("projects")

            vim.keymap.set('n', '<leader>ff', function() builtin.find_files({ hidden = true }) end)
            vim.keymap.set('n', '<leader>fg', function() builtin.live_grep({
				additional_args = function(options)
					return { "--hidden", "--no-ignore" }
				end
			})end)
            vim.keymap.set('n', '<leader>fb', builtin.buffers)
            vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols)
            --vim.keymap.set('n', '<leader>fw', builtin.lsp_workspace_symbols)
            vim.keymap.set('n', '<leader>fd', builtin.diagnostics)
            vim.keymap.set('n', '<leader>fr', builtin.lsp_references)
            vim.keymap.set('n', '<leader>fi', builtin.lsp_implementations)
            vim.keymap.set('n', '<leader>fB', builtin.current_buffer_fuzzy_find)  -- one upside down
            vim.keymap.set('n', '<leader>fp', ':Telescope projects<CR>')
            --vim.keymap.set('n', '<leader>sr', function() require('spectre').open() end, { desc = "Spectre Global Replace" })
            --vim.keymap.set('n', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, { desc = "Spectre Replace Word" })
        end
    },
    { 'nvim-pack/nvim-spectre' },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    {
        "ahmedkhalf/project.nvim",
        config = function()
            require('project_nvim').setup({
                detection_methods = { "pattern", "lsp" },
                patterns = { ".git", "pom.xml", "build.gradle", "package.json" },
            })
        end
    },
}
