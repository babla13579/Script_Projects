set nocompatible        "Force vim settings  (vs VI)
syntax on               "Highlighting Syntax
set number              "Line Numbering
set autoindent          "I'm tire of indenting... Plus python would be a bitch tho fr
set smartindent         "I use tabs but I think this tried to detect indect char (space / tab) and # of spaces if used
" set shiftwidth=2      " This is kinda ugly ngl
set ignorecase          "Ignore Case when searching...
set smartcase           " ...unless we type a capital
colo desert             "Color Scheme
set scrolloff=8         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15    "NoWrap - Scroll when X characters from edge of screen
set sidescroll=1        "Enable NoWrap sidescrolling
set hlsearch            "Highlight searches by default
set incsearch           "Find the next match as we type the search
set showmatch           "Matching Parens are highlighted

" c-a  Opposite of c-x   --- num under cursor ++1... tmux overwrites c-a
noremap <c-b> <c-a>
