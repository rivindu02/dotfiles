return {
    "nvimtools/none-ls.nvim",
    dependencies = {
        "nvimtools/none-ls-extras.nvim",
    },
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                -- Formatting
                null_ls.builtins.formatting.stylua,       -- Lua
                null_ls.builtins.formatting.black,        -- Python
                null_ls.builtins.formatting.prettier,     -- JS/TS/JSON/HTML/CSS
                --null_ls.builtins.formatting.forge_fmt,	 -- for solidity

                -- Diagnostics / Linting
                null_ls.builtins.completion.spell,
                require("none-ls.diagnostics.eslint_d"),   -- JS/TS
            },
        })

        -- ADD THIS: Manual Format Keymap for none-ls
        vim.keymap.set("n", "<leader>fm", function()
            vim.lsp.buf.format({ async = true })
        end, { desc = "Format file" })
    end
}
