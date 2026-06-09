
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
    "goolord/alpha-nvim",
    config = function()
      local alpha     = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
        "████╗  ██║██║   ██║██║████╗ ████║",
        "██╔██╗ ██║██║   ██║██║██╔████╔██║",
        "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
        "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
        "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞 Find file",   ":lua require('telescope.builtin').find_files()<CR>"),
        dashboard.button("g", " Live grep",    ":lua require('telescope.builtin').live_grep()<CR>"),
        dashboard.button("n", " New file",     ":ene <BAR> startinsert<CR>"),
        dashboard.button("r", " Recent files", ":lua require('telescope.builtin').oldfiles()<CR>"),
        dashboard.button("t", "󰙅 File tree",   ":NvimTreeToggle<CR>"),
        dashboard.button("m", "󱡀 Mason",       ":Mason<CR>"),
        dashboard.button("q", " Quit",         ":qa<CR>"),
      }
      dashboard.section.footer.val = "Neovim ready."

      alpha.setup(dashboard.opts)
    end,
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
