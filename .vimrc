source ~/dotfiles/.vimrc__defaults

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins

call plug#begin('~/.vim/plugged')
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'ianks/vim-tsx'
  " Plug 'Quramy/tsuquyomi'
  Plug 'leafgarland/typescript-vim'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
  Plug 'dense-analysis/ale'
  " Plug '907th/vim-auto-save'
  Plug 'kannokanno/previm'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-sensible'
  Plug 'bkad/camelcasemotion'
call plug#end()

let g:previm_open_cmd = 'open -a "Google Chrome"'

autocmd FileType typescript setlocal formatprg=prettier\ --parser\ typescript

" Change the leader to space
" WARNING: makes you a master programmer
let mapleader = "\<Space>"

" use tabs as spaces
set expandtab
" set number of spaces inserted when tabbing
set shiftwidth=2
" use 2 char width for tab chars
set tabstop=2

" set nohlsearch

" Jump around and show matches as we search with /.
" Useful when you want to look to see if something's in
" the file but don't want to commit to jumping to it.
set incsearch
set gdefault

set ruler

syntax on

" Necessary for true color support afaik
set termguicolors
set t_8f=[38;2;%lu;%lu;%lum
set t_8b=[48;2;%lu;%lu;%lum

" Turn on line numbers
set number

" Always show at least 5 lines below and above the
" cursor
set scrolloff=5

" Ignore case when searching
set ignorecase
" Don't ignore case when there _is_ a capital letter
set smartcase

" Copy to clipboard when yanking
set clipboard=unnamed

let g:jsx_ext_required = 0          " allow JSX in .js files

" Store temp and swap files in macOS's temp directory
" This keeps working directories cleaner, but preserves vim's native
" backup functionality
" The `,.` provides the current working directory as a backup, in case
" the OS's backup directory doesn't exist
set backupdir=$TMPDIR//,.
set directory=$TMPDIR//,.
set undodir=$TMPDIR//,.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remappings  
 
" File actions
nnoremap <silent> <leader>w :w<CR>
nnoremap <silent> <leader>q :q<CR>
nnoremap <silent> <leader>Q :qa!<CR>
nnoremap <silent> <leader>a :x<CR>   

" Prettier with <leader>u
nnoremap <leader>u :Prettier<CR>

" Paste last yanked with <leader>p (last yanked will be in `0` register, while last yanked _or_ deleted will be in default register)
nnoremap <leader>p \"0p

" Change default keybindings for moving through jump history to <C-[> and <C-]>
" (my global keyboard overrides use the defaults of <C-i> and <C-o>
nnoremap <C-[> <C-o>
nnoremap <C-]> <C-i>

nnoremap cc _C

noremap <leader>c :Commentary<CR>

noremap <leader>/ :nohl<CR>

nnoremap <leader>k moO<esc>`o
nnoremap <leader>j moo<esc>`o
nnoremap <CR> o<Space><backspace><esc>

nnoremap o o<space><bs>
nnoremap O O<space><bs>
 
" Change 0's and i's default behavior to go to the first non-whitespace
" character, instead of the first character, in a line
noremap 0 _
" Use _ to get back 0's native behavior
noremap _ 0
nnoremap I _i
nnoremap c0 c_
nnoremap d0 d_

" TODO: Fix this -- it doesn't work right now (and has really weird behavior in actual Vim in a terminal
" noremap <Down> <C-d>
" noremap <Up> <C-u>

nnoremap <leader>o o<esc>o<space><backspace>
nnoremap <leader>O O<space><backspace><esc>O

" Prevent `x` from writing to the default register
nnoremap x \"_x
vmap x \"_x

vmap <leader>d y'>p

" Move lines and preserve indentation
" See http://vim.wikia.com/wiki/Moving_lines_up_or_down
" Currently not operable, given global keyboard overrides for <C-j> and <C-k>
" nnoremap <C-j> :m .+1<Return>==
" nnoremap <C-k> :m .-2<Return>==
" vnoremap <C-j> :m '>+1<Return>gv=gv
" vnoremap <C-k> :m '<-2<Return>gv=gv

" Toggle commenting of lines with <leader>/
nnoremap <leader>/ :Commentary<CR>
vnoremap <leader>/ :Commentary<CR>
" Toggle commenting of lines with command + / (only works in MacVim)
nnoremap <D-/> :Commentary<CR>
vnoremap <D-/> :Commentary<CR>

" Move between splits with double leader
nnoremap <leader>h <C-W><C-H>
nnoremap <leader>l <C-W><C-l>
" Could use these one day, but until I actually _use_ vertical splits, might as well save them
" nnoremap <leader>j <C-W><C-J>
" nnoremap <leader>k <C-W><C-K>

" Jump around curly blocks with s
nnoremap s ]}
nnoremap S [{
vmap s ]}
vmap S [{

" Delete line below with <leader>d and above with <leader>D
" nnoremap <silent> <leader>d :+d <CR>
" nnoremap <silent> <leader>D :-d <CR>

" <leader>/ to clear search highlighting of a search
nnoremap <leader>/ :noh

" Toggle wrapping with <Leader>w
" noremap <Leader>w :set wrap!<Return>

" Default j and k to respect wrapped line content
map j gj
map k gk

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Linting

" set signcolumn=yes                  " always show the signcolumn on LH side
let g:ale_set_highlights = 0        " don't highlight first char of errors
let g:ale_completion_enabled = 1    " enable completion when available

let g:ale_linters = {
\ 'javascript': ['eslint'],
\ 'typescript': ['eslint', 'tsserver']
\}
let g:ale_linters_ignore = {
\ 'typescript': ['tslint']
\}

" Use <Leader>aj or <Leader>ak for quickly jumping between lint errors
" nmap <silent> <Leader>aj :ALENext<cr>
" nmap <silent> <Leader>ak :ALEPrevious<cr> 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Appearance

set splitbelow          " open split panes on bottom (instead of top)
set splitright          " open split panes on right (instead of left)

set laststatus=2        " always show status bar

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapping

set wrap                " wrap long lines by default
set linebreak           " when wrapping, break on word boundaries
" auto wrap text at the given number of chars. this is 0 right now to wrap at the window width. if we want to give up on soft wrapping at some point, and just actually wrap lines at a given number of chars in the future, we can set that here
set textwidth=0
set wrapmargin=0
" This seems like the only way to softwrap at 80 chars. However, it can only do so by manually changing the size of the window, which isn't ideal.
" set columns=80

" REFERENCES
"
" https://github.com/mjackson/dotfiles/blob/master/vimrc
" https://gist.github.com/ryanflorence/6d92b7495873263aec0b4e3c299b3bd3
" https://github.com/cfoust/cawnfig/tree/master/configs/vim
