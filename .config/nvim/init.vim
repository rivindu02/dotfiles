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

" UI
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-lualine/lualine.nvim'
Plug 'akinsho/bufferline.nvim', { 'tag': 'v4.*' }
Plug 'goolord/alpha-nvim'
Plug 'folke/which-key.nvim'

" Search
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'

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

" Colors
Plug 'navarasu/onedark.nvim'
Plug 'morhetz/gruvbox'
" for Md files
Plug 'MeanderingProgrammer/render-markdown.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'MeanderingProgrammer/render-markdown.nvim'

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

" colorscheme onedark

" Use man pages when LSP has no hover
set keywordprg=:Man

" -----------------------------------------------------------
" 3. KEYMAPS
" -----------------------------------------------------------

" File tree
nnoremap <C-n> :NvimTreeToggle<CR>

" Buffer navigation (VS Code–like)
nnoremap <S-l> :BufferLineCycleNext<CR>
nnoremap <S-h> :BufferLineCyclePrev<CR>

" Clear highlights
nnoremap <F3> :noh<CR>

" Tagbar (outline view, NOT navigation)
nnoremap <F6> :TagbarToggle<CR>

" -----------------------------------------------------------
" 4. FLOATERM (INTENTIONALLY KEPT)
" -----------------------------------------------------------

let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_prev  = '<F8>'
let g:floaterm_keymap_next  = '<F9>'
let g:floaterm_keymap_toggle= '<F12>'

" Run current Python file
nnoremap <F5> :w<CR>:FloatermNew --autoclose=0 python3 %<CR>

" -----------------------------------------------------------
" 5. COC.NVIM (LSP-FIRST CONFIG)
" -----------------------------------------------------------

let g:coc_disable_startup_warning = 1
let g:coc_diagnostic_virtual_text = 1
let g:coc_diagnostic_virtual_text_prefix = "● "

" Diagnostics navigation
nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
nnoremap <silent> ]g <Plug>(coc-diagnostic-next)

" LSP navigation (USE THESE, NOT TAGS)
nmap gd <Plug>(coc-definition)
nmap gr <Plug>(coc-references)
nmap gi <Plug>(coc-implementation)

" Hover (LSP → Man fallback)
nnoremap K :call CocActionAsync('doHover')<CR>

" Completion behavior
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<C-h>"

" -----------------------------------------------------------
" 6. TAGBAR (FIXED)
" -----------------------------------------------------------

" Explicitly use Universal Ctags
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
})

-- -----------------------
-- ONEDARK TRANSPARENCY
-- -----------------------
require('onedark').setup {
  style = 'dark',
  transparent = true,
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
require('render-markdown').setup({
  heading = {
    sign = false,
    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
    backgrounds = {
      'RenderMarkdownH1Bg',
      'RenderMarkdownH2Bg',
      'RenderMarkdownH3Bg',
    },
  },
  code = {
    sign = false,
    width = 'block',
    border = 'thick',
  },
})
vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#e06c75', bold = true })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#e5c07b', bold = true })
vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#98c379', bold = true })
vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#2d3343' })

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
  dashboard.button("f", "󰈞  Find file", ":Files<CR>"),
  dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
  dashboard.button("r", "  Recent files", ":History<CR>"),
  dashboard.button("t", "󰙅  File tree", ":NvimTreeToggle<CR>"),
  dashboard.button("q", "  Quit", ":qa<CR>"),
}

dashboard.section.footer.val = "Neovim ready."

alpha.setup(dashboard.opts)

EOF

