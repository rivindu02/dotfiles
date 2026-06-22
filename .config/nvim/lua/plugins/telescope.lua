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
                        i = { ["<M-t>"] = open_with_trouble },
                        n = { ["<M-t>"] = open_with_trouble },
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

            vim.keymap.set('n', '<leader>ff', function() builtin.find_files({ hidden = true }) end, { desc = "Find files" })
            vim.keymap.set('n', '<leader>fg', function() builtin.live_grep({
				additional_args = function(options)
					return { "--hidden", "--no-ignore" }
				end
			})end, { desc = "Live Grep" })
            vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find buffers" })
            vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = "Document symbols" })
            --vim.keymap.set('n', '<leader>fw', builtin.lsp_workspace_symbols)
			vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = "Grep word under cursor" })  -- grep word under cursor
            vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = "Diagnostics" })
            vim.keymap.set('n', '<leader>fr', builtin.lsp_references, { desc = "LSP references" })
            vim.keymap.set('n', '<leader>fi', builtin.lsp_implementations, { desc = "LSP implementations" })
            vim.keymap.set('n', '<leader>fB', builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })
            vim.keymap.set('n', '<leader>fp', ':Telescope projects<CR>', { desc = "Find projects" })
			--vim.keymap.set('n', '<leader>sr', function() require('spectre').open() end, { desc = "Spectre Global Replace" })
            --vim.keymap.set('n', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, { desc = "Spectre Replace Word" })
        end
    },
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
