return {
    {
"L3MON4D3/LuaSnip",
        dependencies = {
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
			"supermaven-inc/supermaven-nvim",
		},
		config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()
			require("supermaven-nvim").setup({
				keymaps = {
					accept_suggestion = "<M-Tab>",
					clear_suggestion = "<M-e>",
					accept_word = "<M-w>",
				},
				ignore_filetypes = {},
				color = {
					suggestion_color = "#ffffff",
					cmp_item_color = "#ffffff",
				},
			})
			vim.g.cmp_md_enabled = false
            cmp.setup({
				enabled = function()
					if vim.bo.filetype == "markdown" then
						return vim.g.cmp_md_enabled
					end
					return true  -- always enabled for other filetypes
				end,
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<Tab>']     = cmp.mapping.select_next_item(),
                    ['<S-Tab>']   = cmp.mapping.select_prev_item(),
                    ['<CR>']	  = cmp.mapping.confirm({ select = true }), -- CR means Enter
                    ['<C-x>']	  = cmp.mapping.complete(),
                    ['<C-e>']     = cmp.mapping.abort(),
                    --['<C-b>']     = cmp.mapping.scroll_docs(-4),
                    --['<C-f>']     = cmp.mapping.scroll_docs(4),
                }),
                sources = cmp.config.sources({
					{ name = 'supermaven' },
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'path' },
                }, {
                    { name = 'buffer' },
                }),
            })
			vim.keymap.set("i", "<C-q>", function()
				if vim.bo.filetype == "markdown" then
					vim.g.cmp_md_enabled = not vim.g.cmp_md_enabled
					vim.notify("Completion " .. (vim.g.cmp_md_enabled and "enabled" or "disabled"))
				end
			end, { desc = "Toggle cmp for markdown" })

			-- Use buffer source for '/' and '?'
            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' }
                }
            })
			-- Use cmdline & path source for ':'
            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = 'path' }
                }, {
                    { name = 'cmdline' }
                }),
                matching = { disallow_symbol_nonprefix_matching = false }
            })
        end,
    },
	{ 'echasnovski/mini.icons', opts = {} },
}
