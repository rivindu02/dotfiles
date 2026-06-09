return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "SmiteshP/nvim-navic",
        },
        config = function()
            local navic = require('nvim-navic')
            require('lualine').setup({
                options = {
                    theme = "gruvbox-material",
                    globalstatus = true,
                    section_separators = { left = "", right = "" },
					component_separators = { left = "", right = "" },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff" },
                    lualine_c = {
                        { "filename", path = 1 },
                        {
                            function() return navic.get_location() end,
                            cond = function() return navic.is_available() end,
                        },
                    },
                    lualine_x = {
                        { "diagnostics"},
                        "encoding",
                        "filetype",
                    },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end
    }
}
