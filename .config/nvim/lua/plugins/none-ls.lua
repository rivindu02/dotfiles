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
                null_ls.builtins.formatting.clang_format.with({ filetypes = { "c", "cpp", "cuda" } }),
                null_ls.builtins.formatting.cmake_format,
                null_ls.builtins.formatting.prettier,     -- JS/TS/JSON/HTML/CSS

                -- Diagnostics / Linting
                null_ls.builtins.completion.spell,
                require("none-ls.diagnostics.eslint_d"),   -- JS/TS
            },
        })

        -- Use one formatter per buffer; avoid both clangd and clang-format editing it.
        vim.keymap.set("n", "<leader>fm", function()
            vim.lsp.buf.format({
                async = true,
                filter = function(client) return client.name == "null-ls" end,
            })
        end, { desc = "Format file" })
    end
}
