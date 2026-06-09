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


-- Persistent undo mechanics
opt.undofile = true
opt.undodir = vim.fn.expand("~/.config/nvim/undo")

-- Help lookup fallback targeting system manual entries
opt.keywordprg = ":Man"
