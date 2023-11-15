set nocompatible	"Force vim settings  (vs VI)
syntax on		"Highlighting Syntax
set number		"Line Numbering
set autoindent		"I'm tire of indenting...
" set smartindent         "I use tabs but I think this tried to detect indect char (space / tab) and # of spaces if used
" set shiftwidth=2      " This is kinda ugly ngl
set ignorecase		"Ignore Case when searching...
set smartcase		" ...unless we type a capital
colo industry		"Color Scheme
set scrolloff=8         "Start scrolling when we're 8 lines away from margins 
set sidescrolloff=15    "NoWrap - Scroll when X characters from edge of screen
set sidescroll=1        "Enable NoWrap sidescrolling
set hlsearch		"Highlight searches by default
set incsearch		"Find the next match as we type the search
set showmatch           "Matching Parens are highlighted

" toggle mouse mode
map <F3> <ESC>:exec &mouse!=""? "set mouse=" : "set mouse=nv"<CR>
" c-a  Opposite of c-x   --- num under cursor ++1... tmux overwrites c-a
noremap <c-b> <c-a>
" Backslash p   paste system clipboard
noremap <Bslash>p "*p

call plug#begin('C:\Users\1005357\AppData\Local\nvim\autoload\plugged')

Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'} " this is for auto complete, prettier and tslinting
let g:coc_global_extensions = ['coc-tslint-plugin', 'coc-tsserver', 'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-powershell', 'coc-sh', 'coc-pyright']  " list of CoC extensions needed for JavaScript, PowerShell, SH/BASH, Python
Plug 'jiangmiao/auto-pairs' "this will auto close ( [ {
" these two plugins will add highlighting and indenting to JSX and TSX files.
Plug 'yuezk/vim-js'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'sbdchd/neoformat'

call plug#end()


" neoformat config start
let g:neoformat_try_node_exe = 1
autocmd BufWritePre,TextChanged,InsertLeave *.js Neoformat  " Runs Prettier on Save and upon changing text in VIM
let g:neoformat_run_all_formatters = 1
let g:neoformat_basic_format_align = 1  " Enable alignment
let g:neoformat_basic_format_retab = 1  " Enable tab to spaces conversion
let g:neoformat_basic_format_trim = 1   " Enable trimmming of trailing whitespace
" neoformat config end


"CoC Settings
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
"Ultisnips Settings
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
 
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"
 
"coc-snippets Settings
"inoremap <silent><expr> <TAB>
"      \ coc#pum#visible() ? coc#_select_confirm() :
"      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
"      \ CheckBackspace() ? "\<TAB>" :
"      \ coc#refresh()
"
"function! CheckBackspace() abort
"  let col = col('.') - 1
"  return !col || getline('.')[col - 1]  =~# '\s'
"endfunction
"
"let g:coc_snippet_next = '<tab>'






autocmd BufWinLeave * mkview
autocmd BufWinEnter * silent! loadview
