
return {
  -- BUFFERLINE
  {
    "akinsho/bufferline.nvim",
    version = "v4.*",
    config = function()
      require("bufferline").setup({
        options = {
          diagnostics = "nvim_lsp",
          show_buffer_close_icons = false,
          separator_style = "slant",
        },
      })
    end,
  },

  -- ALPHA DASHBOARD
{
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
        bigfile   = { enabled = true },
        dashboard = {
            preset = {
                header = table.concat({
                    "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
                    "████╗  ██║██║   ██║██║████╗ ████║",
                    "██╔██╗ ██║██║   ██║██║██╔████╔██║",
                    "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                    "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
                    "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
                }, "\n"),
                keys = {
                    { icon = "󰈞 ", key = "f", desc = "Find file",    action = ":lua require('telescope.builtin').find_files()" },
                    { icon = " ", key = "g", desc = "Live grep",     action = ":lua require('telescope.builtin').live_grep()" },
                    { icon = " ", key = "n", desc = "New file",      action = ":ene | startinsert" },
                    { icon = " ", key = "r", desc = "Recent files",  action = ":lua require('telescope.builtin').oldfiles()" },
                    { icon = "󰙅 ", key = "t", desc = "File tree",    action = ":NvimTreeToggle" },
                    { icon = "󱡀 ", key = "m", desc = "Mason",        action = ":Mason" },
                    { icon = " ", key = "q", desc = "Quit",          action = ":qa" },
                },
            },
        },
        indent    = { enabled = true },
        input     = { enabled = true },
        notifier  = { enabled = true, timeout = 3000 },
        quickfile = { enabled = true },
        scroll    = { enabled = false },  -- personal taste, can be jarring
        words     = { enabled = true },
        picker    = { enabled = false },
        explorer  = { enabled = false },
        scope     = { enabled = false },
        statuscolumn = { enabled = false },  -- you have lualine already
    },
    keys = {
        { "<leader>G", function() Snacks.lazygit() end,          desc = "Lazygit" },
        { "<leader>go", function() Snacks.gitbrowse() end,        desc = "Git Browse", mode = { "n", "v" } },
        { "<c-/>", "<cmd>terminal<CR>", desc = "Toggle Terminal" },
        { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
        { "<leader>bd", function() Snacks.bufdelete() end,        desc = "Delete Buffer" },
        { "]]", function() Snacks.words.jump(vim.v.count1) end,   desc = "Next Reference" },
        { "[[", function() Snacks.words.jump(-vim.v.count1) end,  desc = "Prev Reference" },
    },
},
  -- WHICH-KEY
  {
    "folke/which-key.nvim",
    config = true,
  },

  -- INDENT BLANKLINE
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "▏" },
        scope  = { enabled = true },
      })
    end,
  },

  -- TROUBLE
  {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup({
        auto_close    = false,
        auto_preview  = true,
        focus         = true,
        follow        = true,
        indent_guides = true,
        multiline     = true,
        win = {
          position = "bottom",
          size     = 12,
        },
        icons = {
          indent = {
            top         = "│ ",
            middle      = "├╴",
            last        = "└╴",
            fold_open   = " ",
            fold_closed = " ",
            ws          = "  ",
          },
        },
      })
    end,
  },

  -- COLORIZER
  {
    "catgoose/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "css", "javascript", "typescript", "html", "lua",
      })
    end,
  },

  -- ---------------------------------------------------------
  -- TODO COMMENTS
  -- ---------------------------------------------------------
  {
    "folke/todo-comments.nvim",
    config = true,
  },

}
