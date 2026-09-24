local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
-- Mouse & inputs
opt.mouse = "a"
opt.timeoutlen = 400
-- Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
-- UI
opt.visualbell = true
opt.scrolloff = 5
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.inccommand = "split"
-- Splits
opt.hidden = true
opt.splitbelow = true
opt.splitright = true

opt.ignorecase = true
opt.smartcase = true

-- Persistent undo mechanics
-- Kept outside ~/.config/nvim: that path is a symlink into the dotfiles repo
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"

-- Never persist undo/swap copies of secret files
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	desc = "No undo/swap for secret files",
	pattern = {
		"*/.secrets/*", "*/.ssh/*", "*.pem", "*.key", "*/.env", "*/.env.*",
		"*/gh/hosts.yml", "*/aider/*.yml", "*/gcalcli/*",
	},
	callback = function()
		vim.opt_local.undofile = false
		vim.opt_local.swapfile = false
	end,
})

-- Help lookup fallback targeting system manual entries
opt.keywordprg = ":Man"


vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	callback = function()
		vim.hl.on_yank()
	end,
})
