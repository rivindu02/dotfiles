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
"Plug 'junegunn/fzf'
"Plug 'junegunn/fzf.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Search & Replace
Plug 'nvim-pack/nvim-spectre'

" LSP / Completion
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}

" Languages
"Plug 'vim-python/python-syntax'
"Plug 'alvan/vim-closetag'
Plug 'windwp/nvim-ts-autotag'
Plug 'lepture/vim-jinja'
Plug 'stevearc/conform.nvim'
Plug 'mfussenegger/nvim-lint'
Plug 'rafamadriz/friendly-snippets'

Plug 'folke/todo-comments.nvim'
Plug 'norcalli/nvim-colorizer.lua'

" Terminal (KEPT)
Plug 'voldikss/vim-floaterm'

" Tags / Outline (legacy but useful)
"Plug 'preservim/tagbar'
" Replace Tagbar with these:
Plug 'stevearc/aerial.nvim'             " Modern LSP-based outline
Plug 'SmiteshP/nvim-navic'              " Breadcrumbs (Context at top)
Plug 'aznhe21/actions-preview.nvim'     " Visual Quick-fixes (Lightbulb alternative)

" Motion
Plug 'folke/flash.nvim'

Plug 'ahmedkhalf/project.nvim'

" Colors
Plug 'navarasu/onedark.nvim'
Plug 'morhetz/gruvbox'

" Tab manager
Plug 'ThePrimeagen/harpoon', {'branch': 'harpoon2'}

" Markdown
Plug 'MeanderingProgrammer/render-markdown.nvim'
"Plug 'OXY2DEV/markview.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Treesitter Text Objects (Structural editing)
Plug 'nvim-treesitter/nvim-treesitter-textobjects'

Plug 'mfussenegger/nvim-jdtls'

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
" same as :nohl
nnoremap <F3> :noh<CR>

" Format file
"nmap <C-i> :call CocAction('format')<CR>

" Tagbar
" nnoremap <F6> :TagbarToggle<CR>

" Undotree
nnoremap <leader>u :UndotreeToggle<CR>

" Fast escape
inoremap jk <Esc>

" Center screen on navigation
" TODO
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
" TODO
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
"nnoremap <leader>hi :History<CR>

" -----------------------------------------------------------
" 4. FLOATERM
" -----------------------------------------------------------
let g:floaterm_keymap_new    = '<F7>'
let g:floaterm_keymap_prev   = '<F8>'
let g:floaterm_keymap_next   = '<F9>'
let g:floaterm_keymap_toggle = '<F12>'

autocmd FileType python nnoremap <buffer> <F5> :w<CR>:FloatermNew --autoclose=0 python3 %<CR>
autocmd FileType java nnoremap <buffer> <F5> :w<CR>:FloatermNew --autoclose=0 mvn clean compile<CR>
" -----------------------------------------------------------
" 5. COC.NVIM
" -----------------------------------------------------------
"let g:coc_disable_startup_warning = 1
"let g:coc_diagnostic_virtual_text = 1
"let g:coc_diagnostic_virtual_text_prefix = "● "

" Diagnostics navigation
"nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
"nnoremap <silent> ]g <Plug>(coc-diagnostic-next)

" LSP navigation
"nmap gd <Plug>(coc-definition)
"nmap gr <Plug>(coc-references)
"nmap gi <Plug>(coc-implementation)
"nmap gt <Plug>(coc-type-definition)

" Refactoring
"nmap <leader>rn <Plug>(coc-rename)
"nmap <leader>ca <Plug>(coc-codeaction-cursor)
"nmap <leader>qf <Plug>(coc-fix-current)

" Hover and signature
"nnoremap <silent> K :call CocAction('doHover')<CR>
"nnoremap <leader>si :call CocActionAsync('showSignatureHelp')<CR>

" Java specific
"nnoremap <leader>jm :CocCommand java.action.overrideMethodsPrompt<CR>
"nnoremap <leader>ji :CocCommand java.action.organizeImports<CR>
"nnoremap <leader>jt :CocCommand java.action.showTypeHierarchy<CR>
"nnoremap <leader>jr :CocCommand java.clean.workspace<CR>

" Completion
"inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : \<CR>"
"inoremap <expr> <Tab> pumvisible() ? \<"C-n>" : \<Tab>"
"inoremap <expr> <S-Tab> pumvisible() ? \<C-p>" : \<C-h>"
"
" -----------------------------------------------------------
" 5. LSP KEYMAPS (set in lua on_attach, listed here as reference)
" -----------------------------------------------------------
" gd        -> definition
" gr        -> references
" gi        -> implementation
" gt        -> type definition
" K         -> hover
" <leader>rn -> rename
" <leader>ca -> code action
" <leader>qf -> quick fix
" <leader>fm -> format
" [g / ]g   -> prev/next diagnostic
" <leader>si -> signature help
" <leader>jm -> override methods (jdtls)
" <leader>ji -> organize imports (jdtls)
" <leader>jt -> type hierarchy (jdtls)
" <leader>jr -> restart jdtls

" -----------------------------------------------------------
" 6. TAGBAR
" -----------------------------------------------------------
"let g:tagbar_ctags_bin = 'ctags'


" Reminder:
" Ctrl-]  -> jump to tag (ctags)
" Ctrl-T  -> jump back (ONLY for tags)
" <C-o>   -> jump back (LSP, fzf, everything)

" -----------------------------------------------------------
" 7. LUA CONFIG (UI COMPONENTS)
" -----------------------------------------------------------

lua << EOF

-- -----------------------
-- AERIAL (Outline)
-- -----------------------
require("aerial").setup({
  on_attach = function(bufnr)
    -- Jump forwards/backwards with { and } ----> Use this to move arround functions
    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
  end,
})
-- Map it to your old Tagbar key (F6) or something new
vim.keymap.set("n", "<F6>", "<cmd>AerialToggle! left<CR>")

-- -----------------------
-- NAVIC (Breadcrumbs)
-- -----------------------
local navic = require("nvim-navic")
navic.setup({
    highlight = true,
    separator = "  ",
    depth_limit = 5,
})

-- -----------------------
-- NVIM-TREE
-- -----------------------
require("nvim-tree").setup({
  sync_root_with_cwd = true,
  respect_buf_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = true,
  },
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
-- ONEDARK
-- -----------------------
require('onedark').setup {
  style = 'warm',
  --transparent = false
}

require('onedark').load()

-- -----------------------
-- BUFFERLINE
-- -----------------------
require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    show_buffer_close_icons = false,
    separator_style = "slant",
  }
})



-- -----------------------
-- TS-AUTOTAG
-- -----------------------
require('nvim-ts-autotag').setup({})

-- -----------------------
-- TODO COMMENTS
-- -----------------------
require('todo-comments').setup({})

-- -----------------------
-- COLORIZER
-- -----------------------
require('colorizer').setup({
	'css', 'javascript', 'typescript', 'html', 'lua'
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
	lualine_c = { 
        { "filename", path = 1 },
        { function() return navic.get_location() end, cond = navic.is_available } 
    },
    lualine_x = {
      { "diagnostics", sources = { "nvim_lsp" } },
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
vim.keymap.set('n', '<leader>fB', builtin.current_buffer_fuzzy_find)

-- -----------------------
-- PROJECT
-- -----------------------
require("project_nvim").setup({
  detection_methods = { "pattern", "lsp" },
  patterns = { ".git", "pom.xml", "build.gradle", "package.json" },
})

telescope.load_extension('projects')
vim.keymap.set('n', '<leader>fp', ':Telescope projects<CR>')

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
    vim.keymap.set('n', ']c', gs.next_hunk, opts)  -- TODO 
    vim.keymap.set('n', '[c', gs.prev_hunk, opts)  -- TODO
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
-- TREESITTER & TEXTOBJECTS
-- -----------------------
local ok, treesitter = pcall(require, 'nvim-treesitter.configs')
if ok then
  treesitter.setup({
    ensure_installed = {
      "java", "python", "javascript", "typescript",
      "json", "yaml", "xml", "lua", "bash", "markdown", "markdown_inline", "c", "cpp"
    },
    highlight = { enable = true },
    indent = { enable = true },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer' },
        goto_prev_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer' },
      },
    },
  })
end

-- -----------------------
-- LSP-ZERO
-- -----------------------
local lsp_zero = require('lsp-zero')
 
lsp_zero.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr }
 
  -- Navigation
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
 
  -- Hover / signature
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>si', vim.lsp.buf.signature_help, opts)
 
  -- Refactor
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>qf', function()
    vim.lsp.buf.code_action({ apply = true })
  end, opts)
 
 
  -- Diagnostics
  vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']g', vim.diagnostic.goto_next, opts)
 
  -- Java (jdtls) specific — only attach when jdtls is the client  -- TODO
  if client.name == 'jdtls' then
    vim.keymap.set('n', '<leader>jm', function()
      require('jdtls').organize_imports()
    end, opts)
    vim.keymap.set('n', '<leader>ji', function()
      require('jdtls').organize_imports()
    end, opts)
    vim.keymap.set('n', '<leader>jt', function()
      require('jdtls').type_hierarchy()
    end, opts)
    vim.keymap.set('n', '<leader>jr', function()
      vim.lsp.stop_client(vim.lsp.get_active_clients())
      vim.cmd('edit')
    end, opts)
  end

  -- 1. Enable Breadcrumbs if the server supports it
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end

  -- 2. Enable Inlay Hints (Parameter names like VS Code)
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end

  -- 3. Visual Code Actions (Replaces standard menu with a preview)
  vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions)
end)
 
-- Diagnostic display
vim.diagnostic.config({
  virtual_text = { prefix = '●' },
  signs = true,
  underline = true,
  update_in_insert = false,
})
 
-- Mason setup
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'pyright',     -- Python
    'clangd',      -- C / C++
    'ts_ls',       -- TypeScript / JavaScript
    'bashls',      -- Shell scripts
    'lua_ls',      -- Lua (for editing this config)
    'jdtls',       -- Java
	'solidity_ls_nomicfoundation'	   -- solidity	
  },
  handlers = {
    lsp_zero.default_setup,
    -- jdtls is handled separately below (needs special workspace config)
    jdtls = lsp_zero.noop,
  },
})
 
 -- -----------------------
-- JDTLS MANUAL SETUP
-- -----------------------
local lombok_path = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls/lombok.jar")
local jdtls_ok, jdtls = pcall(require, 'jdtls')
if jdtls_ok then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
      local workspace = vim.fn.stdpath('data') .. '/jdtls-workspace/' ..
        vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

      local config = {
        -- 1. FORCE THE SERVER TO RUN WITH JAVA 21
        cmd = {
          '/usr/lib/jvm/java-21-openjdk/bin/java', 
          '-Xmx1g',
		  "-javaagent:" .. lombok_path,
          '-jar', vim.fn.glob(vim.fn.stdpath('data') .. '/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar'),
          '-configuration', vim.fn.stdpath('data') .. '/mason/packages/jdtls/config_linux',
          '-data', workspace,
        },
        root_dir = vim.fs.dirname(vim.fs.find({'pom.xml', 'build.gradle', '.git'}, { upward = true })[1]),
        
        -- 2. TELL THE SERVER TO COMPLIE WITH JAVA 17
        settings = {
          java = {
            configuration = {
              runtimes = {
                {
                  name = "JavaSE-17",
                  path = "/usr/lib/jvm/java-17-openjdk/",
                  default = true, -- This ensures your project uses 17
                },
                {
                  name = "JavaSE-21",
                  path = "/usr/lib/jvm/java-21-openjdk/",
                },
              },
            },
          },
        },
      }
      jdtls.start_or_attach(config)
    end,
  })
end

-- -----------------------
-- COMPLETION (nvim-cmp)
-- -----------------------
local cmp = require('cmp')
local luasnip = require('luasnip')
 
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>']    = cmp.mapping.confirm({ select = true }),
    ['<Tab>']   = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']   = cmp.mapping.abort(),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
  }),
})
require('luasnip.loaders.from_vscode').lazy_load()

-- -----------------------
-- HARPOON2
-- -----------------------
local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function()
  local h = require("harpoon")
  h.ui:toggle_quick_menu(h:list())
end)
vim.keymap.set("n", "<A-1>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<A-2>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<A-3>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<A-4>", function() harpoon:list():select(4) end)

vim.keymap.set("n", "<A-n>", function() harpoon:list():next() end)
vim.keymap.set("n", "<A-p>", function() harpoon:list():prev() end)

-- -----------------------
-- RENDER MARKDOWN
-- -----------------------
require('render-markdown').setup({
  preset = 'obsidian',
  html = { enabled = false },
  latex = { enabled = false },
  heading = {
    backgrounds = { '', '', '', '', '', '' },
	icons = { '▌ ', '▌ ', '▌ ', '▌ ', '▌ ', '▌ ' },
  },
  code = {
    width = 'block',
    left_pad = 2,
    right_pad = 2,
  },
})

-- this is the critical fix
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.treesitter.start()
  end,
})

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
  dashboard.button("m", "󱡀 Mason",       ":Mason<CR>"),
  dashboard.button("q",  " Quit",          ":qa<CR>"),
}


dashboard.section.footer.val = "Neovim ready."

alpha.setup(dashboard.opts)

-- -----------------------
-- CONFORM (Formatting)
-- -----------------------
require('conform').setup({
  formatters_by_ft = {
    python = { 'black' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    java = {},
    solidity = { 'forge_fmt' }, -- change to 'prettier' if using hardhat
    json = { 'prettier' },
  },
  format_on_save = { 
    timeout_ms = 500, 
    lsp_fallback = false,
	ignore_filetypes = {},  -- jdtls format is very slow
  },
})

-- Override manual format key to use Conform
vim.keymap.set('n', '<leader>fm', function()
  require('conform').format({ async = true, lsp_fallback = true })
end, { desc = "Format file" })

-- -----------------------
-- NVIM-LINT (Linting)
-- -----------------------
local lint_ok, lint = pcall(require, 'nvim-lint')
if lint_ok then
  -- nvim-lint does NOT have a .setup() function. 
  -- We define the linters directly like this:
  lint.linters_by_ft = {
    javascript = { 'eslint_d' },
    typescript = { 'eslint_d' },
    python = { 'pylint' },
  }

  -- Trigger linting on save
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    callback = function()
	local lint_ok, lint = pcall(require, 'nvim-lint')
      lint.try_lint()
    end,
  })
end


-- -----------------------
-- SPECTRE (Project Search & Replace)
-- -----------------------
vim.keymap.set('n', '<leader>sr', function() require('spectre').open() end, { desc = "Spectre Global Replace" })
vim.keymap.set('n', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end, { desc = "Spectre Replace Word" })

EOF

