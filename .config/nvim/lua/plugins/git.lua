return {
  -- VIM-FUGITIVE
  {
    "tpope/vim-fugitive",
    config = function()
      local map = vim.keymap.set
      map("n", "<leader>gg", "<cmd>Git<CR>")
      map("n", "<leader>gb", "<cmd>Git blame<CR>")
      map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>")
      map("n", "<leader>gl", "<cmd>Git log --oneline<CR>")
    end,
  },
  -- GITSIGNS
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs   = package.loaded.gitsigns
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "]c",          gs.next_hunk,       opts)  -- TODO
          vim.keymap.set("n", "[c",          gs.prev_hunk,       opts)  -- TODO
          vim.keymap.set("n", "<leader>hp",  gs.preview_hunk,    opts)
          vim.keymap.set("n", "<leader>hs",  gs.stage_hunk,      opts)
          vim.keymap.set("n", "<leader>hu",  gs.undo_stage_hunk, opts)
          vim.keymap.set("n", "<leader>hb",  gs.blame_line,      opts)
          vim.keymap.set("n", "<leader>hd",  gs.diffthis,        opts)
        end,
      })
    end,
  },
}
