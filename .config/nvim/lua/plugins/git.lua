return {
  -- VIM-FUGITIVE
  {
    "tpope/vim-fugitive",
    config = function()
      local map = vim.keymap.set
      map("n", "<leader>gg", "<cmd>Git<CR>", { desc = "Git status" })
      map("n", "<leader>gb", "<cmd>Git blame<CR>", { desc = "Git blame" })
      map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>", { desc = "Git diff split" })
      map("n", "<leader>gl", "<cmd>Git log --oneline<CR>", { desc = "Git log (oneline)" })
    end,
  },
  -- GITSIGNS
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup{
		  on_attach = function(bufnr)
			  local gitsigns = require('gitsigns')
			  local function map(mode, l, r, opts)
				  opts = opts or {}
				  opts.buffer = bufnr
				  vim.keymap.set(mode, l, r, opts)
			  end
			  -- Navigation
			  map('n', ']c', function()
				  if vim.wo.diff then
					  vim.cmd.normal({']c', bang = true})
				  else
					  gitsigns.nav_hunk('next')
				  end
			  end, { desc = "Next hunk" })
			  map('n', '[c', function()
				  if vim.wo.diff then
					  vim.cmd.normal({'[c', bang = true})
				  else
					  gitsigns.nav_hunk('prev')
				  end
			  end, { desc = "Prev hunk" })
			  -- Actions
			  map('n', '<leader>ga', gitsigns.stage_hunk, { desc = "Git add hunk" })
			  map('n', '<leader>gr', gitsigns.reset_hunk, { desc = "Reset hunk to HEAD" })
			  map('n', '<leader>gp', gitsigns.preview_hunk, { desc = "Preview hunk" })
			  -- Toggles
			  map('n', '<leader>gB', gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
		  end
	  }
    end,
  },
}
