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

-- Never persist automatic undo/swap/backup copies of secret files.
local secret_patterns = {
	"*/.secrets/*", "*/.ssh/*", "*.pem", "*.key", "*/.env", "*/.env.*",
	"*/gh/hosts.yml", "*/aider/*.yml", "*/gcalcli/*",
	"*/.aws/credentials", "*/.aws/config",
	"*/.aws/sso/cache/*", "*/.aws/cli/cache/*", "*/.aws/login/cache/*",
	"*/.config/rclone/rclone.conf", "*/.config/rclone/rclone.conf.old",
	"*/.config/rclone/rclone.conf.bak", "*/.config/restic/password",
	"*/.local/share/keyrings/*", "*/.claude/.credentials.json",
	"*/.codex/auth.json", "*/.gemini/oauth_creds.json",
	"*/.npmrc", "*/.netrc", "*/.openclaude-profile.json",
}
-- backup/writebackup are global; backupskip targets only these paths.
opt.backupskip:append(secret_patterns)
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "BufFilePost", "BufWritePre" }, {
	desc = "No undo/swap for secret files, including renamed buffers",
	pattern = secret_patterns,
	callback = function(event)
		vim.bo[event.buf].undofile = false
		vim.bo[event.buf].swapfile = false
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
