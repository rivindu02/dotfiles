-- 1. LAZY.NVIM BOOTSTRAPPER
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 2. CORE MODULES
require("core.options")
require("core.keymaps")
require("core.robotics").setup()
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

-- 3. PLUGINS
local lazy_options = {
	rocks = {
        enabled = false,
    },
}
if vim.env.DEVBOX_NVIM_ISOLATED == "1" then
    local lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"
    if vim.fn.filereadable(lockfile) == 0 then
        vim.fn.mkdir(vim.fn.stdpath("data"), "p")
        vim.fn.writefile(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), lockfile)
    end
    lazy_options.lockfile = lockfile
end
require("lazy").setup("plugins", lazy_options)
