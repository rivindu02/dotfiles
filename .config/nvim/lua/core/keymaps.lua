local map = vim.keymap.set

-- keymap selected text without loosing what already yank ed
map("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text"})
-- Delete text without saving it to any registers
map({"n", "v"}, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- UI Toggles & General Utilities

map("n", "<F3>", "<cmd>noh<CR>")
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>")
map("i", "jk", "<Esc>")
map("i", "<C-c>", "<Esc>")
map("n", "<C-c>", ":nohl<CR>", {desc = "Clear search highlighting", silent = true})

-- Tab & Buffer Management Line Switching
map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>")
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>")
map("n", "<leader>bd", "<cmd>bd<CR>") -- delete buffer

-- Visual Mode Line Relocation
map("v", "<S-j>", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
map("v", "<S-k>", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

-- Visual select line and then indent
map("v", "<", "<gv", { desc = "Unindent and keep selection"})
map("v", ">", ">gv", { desc = "Indent and keep selection"})

-- Keep screen locked center when jumping files/searches 
map("n", "n", "nzzzv", {desc = "Next search result cursor centered"})
map("n", "N", "Nzzzv", {desc = "move down in buffer with cursor centered"})
map("n", "<C-d>", "<C-d>zz", {desc = "move down in buffer with cursor centered"})
map("n", "<C-u>", "<C-u>zz", {desc = "move up in buffer with cursor centered"})
map("n", "<C-o>", "<C-o>zz", { desc = "Jump backward in jumplist and center cursor" })
map("n", "<C-i>", "<C-i>zz", { desc = "Jump forward in jumplist and center cursor" })

-- replace word cursor
map("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word cursor is on globally" })
-- make executable
map("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })


-- Trouble diagnostics TODO:
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
