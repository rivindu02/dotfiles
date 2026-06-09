local map = vim.keymap.set

-- UI Toggles & General Utilities

map("n", "<F3>", "<cmd>noh<CR>")
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>")
map("i", "jk", "<Esc>")

-- Tab & Buffer Management Line Switching
map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>")
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>")
map("n", "<leader>bd", "<cmd>bd<CR>")


-- Keep screen locked center when jumping files/searches
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-o>", "<C-o>zz")
map("n", "<C-i>", "<C-i>zz")

-- Visual Mode Line Relocation
map("v", "<S-j>", ":m '>+1<CR>gv=gv")
map("v", "<S-k>", ":m '<-2<CR>gv=gv")

-- Native Splitting Window Navigation Panel Switches  --> replace with tmux
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")


-- Trouble diagnostics
-- Project-Wide Diagnostics Panel (Bottom persistent window)
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>")

-- Current Buffer Only Diagnostics Panel (Filter out workspace noise)
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>")

-- LSP Symbols Panel (Replaces old side-bars / outlines on the right)
map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=true win.position=right win.size=35<CR>")

-- Cross-File LSP References Grid (Fuzzy searching is bad for this; a tree view is perfect)
map("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=true win.position=bottom<CR>")

-- Traditional Fallbacks
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<CR>")
map("n", "<leader>xl", "<cmd>Trouble loclist toggle<CR>")
