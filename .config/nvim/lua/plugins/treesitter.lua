return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = function()
            local treesitter = require("nvim-treesitter")
            treesitter.setup({ install_dir = vim.fn.stdpath("data") .. "/treesitter" })
            treesitter.update():wait(180000)
        end,
        config = function()
            local treesitter = require("nvim-treesitter")
            -- Keep managed parsers/queries separate from stale vim-plug symlinks in site/.
            treesitter.setup({ install_dir = vim.fn.stdpath("data") .. "/treesitter" })
            local function highlight(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then return end
                local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
                if lang then
                    -- Vim syntax stays available while a parser is missing or being installed.
                    pcall(vim.treesitter.start, bufnr, lang)
                end
            end
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
                callback = function(event) highlight(event.buf) end,
                desc = "Start Tree-sitter highlighting when a parser is available",
            })
            treesitter.install({
                "python", "c", "cpp", "cmake", "bash", "lua", "vim", "vimdoc", "query",
                "json", "yaml", "xml", "markdown", "markdown_inline",
            }):await(function(err)
                if err then
                    vim.schedule(function()
                        vim.notify("Tree-sitter installation failed; use :TSInstall or :checkhealth nvim-treesitter.\n" .. tostring(err), vim.log.levels.WARN)
                    end)
                    return
                end
                vim.schedule(function()
                    -- Also highlight files opened before the asynchronous install completed.
                    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_loaded(bufnr) then highlight(bufnr) end
                    end
                end)
            end)
        end,
    },
}
