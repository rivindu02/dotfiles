" ===========================================================
" NEOVIM CONFIG
" ===========================================================

" -----------------------------------------------------------
" 1. PLUGINS
" -----------------------------------------------------------

call plug#begin('~/.local/share/nvim/plugged')

" Core editing
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'matze/vim-move'
Plug 'mbbill/undotree'
Plug 'windwp/nvim-autopairs'

" UI
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'
Plug 'akinsho/bufferline.nvim', { 'tag': 'v4.*' }
Plug 'goolord/alpha-nvim'
Plug 'folke/which-key.nvim'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'folke/trouble.nvim'

" Search
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" LSP / Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Languages
Plug 'vim-python/python-syntax'
Plug 'alvan/vim-closetag'
Plug 'lepture/vim-jinja'

" Terminal (KEPT)
Plug 'voldikss/vim-floaterm'

" Tags / Outline (legacy but useful)
Plug 'preservim/tagbar'

" Motion
Plug 'folke/flash.nvim'

" Colors
Plug 'navarasu/onedark.nvim'
Plug 'morhetz/gruvbox'

" Markdown
Plug 'MeanderingProgrammer/render-markdown.nvim'
Plug 'OXY2DEV/markview.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

call plug#end()

" -----------------------------------------------------------
" 2. GENERAL SETTINGS
" -----------------------------------------------------------
set number
set relativenumber
set mouse=a
set autoindent
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab
set encoding=UTF-8
set visualbell
set scrolloff=5
set cursorline
set signcolumn=yes
set termguicolors
set hidden
set splitbelow
set splitright
set timeoutlen=400
set inccommand=split

" Persistent undo
set undofile
set undodir=~/.config/nvim/undo

" Use man pages when LSP has no hover
set keywordprg=:Man

" -----------------------------------------------------------
" 3. KEYMAPS
" -----------------------------------------------------------
" Leader
let mapleader = " "

" File tree
nnoremap <C-n> :NvimTreeToggle<CR>

" Buffer navigation
nnoremap <S-l> :BufferLineCycleNext<CR>
nnoremap <S-h> :BufferLineCyclePrev<CR>
nnoremap <leader>bd :bd<CR>

" Clear highlights
nnoremap <F3> :noh<CR>

" Format file
nmap <C-i> :call CocAction('format')<CR>

" Tagbar
nnoremap <F6> :TagbarToggle<CR>

" Undotree
nnoremap <F4> :UndotreeToggle<CR>

" Fast escape
inoremap jk <Esc>

" Center screen on navigation
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap <C-o> <C-o>zz
nnoremap <C-i> <C-i>zz

" Move lines
vnoremap <S-j> :m '>+1<CR>gv=gv
vnoremap <S-k> :m '<-2<CR>gv=gv

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Git (fugitive)
nnoremap <leader>gg :Git<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gl :Git log --oneline<CR>

" Trouble diagnostics
nnoremap <leader>xx :TroubleToggle<CR>
nnoremap <leader>xw :TroubleToggle workspace_diagnostics<CR>
nnoremap <leader>xd :TroubleToggle document_diagnostics<CR>

" FZF
nnoremap <leader>rg :Rg<CR>
nnoremap <leader>bl :BLines<CR>
nnoremap <leader>hi :History<CR>
nnoremap <leader>gc :GFiles?<CR>

" -----------------------------------------------------------
" 4. FLOATERM
" -----------------------------------------------------------
let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_prev   = '<F8>'
let g:floaterm_keymap_next   = '<F9>'
let g:floaterm_keymap_toggle = '<F12>'

nnoremap <F5> :w<CR>:FloatermNew --autoclose=0 python3 %<CR>

" -----------------------------------------------------------
" 5. COC.NVIM
" -----------------------------------------------------------
let g:coc_disable_startup_warning = 1
let g:coc_diagnostic_virtual_text = 1
let g:coc_diagnostic_virtual_text_prefix = "● "

" Diagnostics navigation
nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
nnoremap <silent> ]g <Plug>(coc-diagnostic-next)

" LSP navigation
nmap gd <Plug>(coc-definition)
nmap gr <Plug>(coc-references)
nmap gi <Plug>(coc-implementation)
nmap gt <Plug>(coc-type-definition)

" Refactoring
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction-cursor)
nmap <leader>qf <Plug>(coc-fix-current)

" Hover and signature
nnoremap K :call CocActionAsync('doHover')<CR>
nnoremap <leader>si :call CocActionAsync('showSignatureHelp')<CR>

" Java specific
nnoremap <leader>jm :CocCommand java.action.overrideMethodsPrompt<CR>
nnoremap <leader>ji :CocCommand java.action.organizeImports<CR>
nnoremap <leader>jt :CocCommand java.action.showTypeHierarchy<CR>
nnoremap <leader>jr :CocCommand java.clean.workspace<CR>

" Completion
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<C-h>"

" -----------------------------------------------------------
" 6. TAGBAR
" -----------------------------------------------------------
let g:tagbar_ctags_bin = 'ctags'


" Reminder:
" Ctrl-]  -> jump to tag (ctags)
" Ctrl-T  -> jump back (ONLY for tags)
" <C-o>   -> jump back (LSP, fzf, everything)

" -----------------------------------------------------------
" 7. LUA CONFIG (UI COMPONENTS)
" -----------------------------------------------------------

lua << EOF

-- -----------------------
-- NVIM-TREE
-- -----------------------
require("nvim-tree").setup({
  view = { width = 30 },
  renderer = {
    icons = { show = { git = true, folder = true, file = true } },
  },
  filters = {
    dotfiles = false,
    custom = { "^.git$", "target", "__pycache__" },
  },
})

-- -----------------------
-- ONEDARK TRANSPARENCY
-- -----------------------
require('onedark').setup {
  style = 'dark',
  --transparent = false
}

require('onedark').load()

-- -----------------------
-- BUFFERLINE
-- -----------------------
require("bufferline").setup({
  options = {
    diagnostics = "coc",
    show_buffer_close_icons = false,
    separator_style = "slant",
  }
})

-- -----------------------
-- LUALINE
-- -----------------------
require("lualine").setup({
  options = {
    theme = "onedark",
    globalstatus = true,
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {
      { "diagnostics", sources = { "coc" } },
      "encoding",
      "filetype",
    },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
})

-- -----------------------
-- TELESCOPE
-- -----------------------
local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup({
  defaults = {
    file_ignore_patterns = { "target/", ".git/", "node_modules/", "%.class" },
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.55 },
  }
})
telescope.load_extension('fzf')

vim.keymap.set('n', '<leader>ff', builtin.find_files)
vim.keymap.set('n', '<leader>fg', builtin.live_grep)
vim.keymap.set('n', '<leader>fb', builtin.buffers)
vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols)
vim.keymap.set('n', '<leader>fw', builtin.lsp_workspace_symbols)
vim.keymap.set('n', '<leader>fd', builtin.diagnostics)
vim.keymap.set('n', '<leader>fr', builtin.lsp_references)
vim.keymap.set('n', '<leader>fi', builtin.lsp_implementations)

-- -----------------------
-- AUTOPAIRS
-- -----------------------
require('nvim-autopairs').setup({})

-- -----------------------
-- GITSIGNS
-- -----------------------
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local opts = { buffer = bufnr }
    vim.keymap.set('n', ']c', gs.next_hunk, opts)
    vim.keymap.set('n', '[c', gs.prev_hunk, opts)
    vim.keymap.set('n', '<leader>hp', gs.preview_hunk, opts)
    vim.keymap.set('n', '<leader>hs', gs.stage_hunk, opts)
    vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, opts)
    vim.keymap.set('n', '<leader>hb', gs.blame_line, opts)
    vim.keymap.set('n', '<leader>hd', gs.diffthis, opts)
  end
})

-- -----------------------
-- TROUBLE
-- -----------------------
require('trouble').setup({
  icons = true,
  fold_open = "",
  fold_closed = "",
  signs = {
    error = "",
    warning = "",
    hint = "",
    information = "",
  },
})

-- -----------------------
-- INDENT BLANKLINE
-- -----------------------
require('ibl').setup({
  indent = { char = '▏' },
  scope = { enabled = true },
})

-- -----------------------
-- FLASH
-- -----------------------
require('flash').setup({})
vim.keymap.set({'n', 'x', 'o'}, 's', function() require('flash').jump() end)
vim.keymap.set({'n', 'x', 'o'}, 'S', function() require('flash').treesitter() end)

-- -----------------------
-- TREESITTER
-- -----------------------
local ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if ok then
  treesitter.setup({
    ensure_installed = {
      "java", "python", "javascript", "typescript",
      "json", "yaml", "xml", "lua", "bash", "markdown"
    },
    highlight = { enable = true },
    indent = { enable = true },
  })
end

-- -----------------------
-- RENDER MARKDOWN
-- -----------------------
require('markview').setup({})
--require('render-markdown').setup({
--  heading = {
--    sign = false,
--    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
--    backgrounds = {
--      'RenderMarkdownH1Bg',
--      'RenderMarkdownH2Bg',
--      'RenderMarkdownH3Bg',
--    },
--  },
--	inline_code = {
--		enabled = true,
--		highlight = 'RenderMarkdownCode',
--  },
--  code = {
--    sign = false,
--    width = 'block',
--    border = 'thick',
--    highlight = 'RenderMarkdownCode',
    -- This can help with stray backtick artifacts:
--    disable_background = false,
--  },
--})
--vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#e06c75', bold = true })
--vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#e5c07b', bold = true })
--vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#98c379', bold = true })
--vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#2d3343' })

-- -----------------------
-- WHICH-KEY
-- -----------------------
require("which-key").setup({})

-- -----------------------
-- ALPHA DASHBOARD
-- -----------------------
local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
  "███╗   ██╗██╗   ██╗██╗███╗   ███╗",
  "████╗  ██║██║   ██║██║████╗ ████║",
  "██╔██╗ ██║██║   ██║██║██╔████╔██║",
  "██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
  "██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
  "╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
}
dashboard.section.buttons.val = {
  dashboard.button("f", "󰈞 Find file",    ":lua require('telescope.builtin').find_files()<CR>"),
  dashboard.button("g", " Live grep",     ":lua require('telescope.builtin').live_grep()<CR>"),
  dashboard.button("n", " New file",      ":ene <BAR> startinsert<CR>"),
  dashboard.button("r", " Recent files",  ":lua require('telescope.builtin').oldfiles()<CR>"),
  dashboard.button("t", "󰙅 File tree",    ":NvimTreeToggle<CR>"),
  dashboard.button("q",  " Quit",          ":qa<CR>"),
}


dashboard.section.footer.val = "Neovim ready."

alpha.setup(dashboard.opts)

EOF

