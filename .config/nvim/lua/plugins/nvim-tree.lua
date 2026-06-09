return {
    {
        "nvim-tree/nvim-tree.lua",
        config = function()
            require('nvim-tree').setup({
                sync_root_with_cwd = true,
                respect_buf_cwd = true,
                update_focused_file = {
                    enable = true,
                    update_root = true,
                },
                view = { width = 30 },
                renderer = {
                    icons = { show = { git = true, folder = true, file = true } },
                },
                git = {
                    ignore = false,
                },
                filters = {
                    dotfiles = false,
                    custom = { "^.git$", "target", "__pycache__" },
                },
            })
			vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>")
        end
    },
}
