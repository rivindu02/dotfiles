return {
	{
		"vim-test/vim-test",
		dependencies = { "preservim/vimux" },
		config = function()
			vim.g["test#strategy"]  = "vimux"
			vim.g.VimuxHeight       = "30"
			vim.g.VimuxOrientation  = "h"
			local map = vim.keymap.set
			map("n", "<leader>tn", "<cmd>TestNearest<CR>", { silent = true })
			map("n", "<leader>tf", "<cmd>TestFile<CR>",    { silent = true })
			map("n", "<leader>ts", "<cmd>TestSuite<CR>",   { silent = true })
			map("n", "<leader>tl", "<cmd>TestLast<CR>",    { silent = true })
			map("n", "<leader>tv", "<cmd>TestVisit<CR>",   { silent = true })
		end,
	},
	{ "preservim/vimux" },
}
