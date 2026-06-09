return {

  -- HARPOON2 (Fast file bookmarks)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup({
        settings = { save_on_toggle = true },
      })

      local map = vim.keymap.set
      map("n", "<leader>a", function() harpoon:list():add() end)
      -- NOTE: <C-h> here shadows the window-nav binding in core/keymaps.lua.
      --       Choose one or remap the window nav to <leader>wh etc.
      map("n", "<C-h>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
      map("n", "<A-1>", function() harpoon:list():select(1) end)
      map("n", "<A-2>", function() harpoon:list():select(2) end)
      map("n", "<A-3>", function() harpoon:list():select(3) end)
      map("n", "<A-4>", function() harpoon:list():select(4) end)
      map("n", "<A-n>", function() harpoon:list():next() end)
      map("n", "<A-p>", function() harpoon:list():prev() end)
    end,
  },

  -- FLASH (Leap-style motion)
  {
    "folke/flash.nvim",
    config = function()
      require("flash").setup({})
      vim.keymap.set({ "n", "x", "o" }, "s", function()
        require("flash").jump()
      end)
    end,
  },

  -- AERIAL (Symbol outline side panel)
  {
    "stevearc/aerial.nvim",
    config = function()
      require("aerial").setup({
        on_attach = function(bufnr)
          vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
      })
      vim.keymap.set("n", "<F6>", "<cmd>AerialToggle! left<CR>")
    end,
  },


}
