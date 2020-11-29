source ~/dotfiles/.vimrc__defaults

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

" Press <escape><return> or <escape><wait a second...> to clear highlighting
" of a search
" nnoremap <esc> :noh<return><esc>
" nnoremap <esc>^[ <esc>^[
set nohlsearch

" Remap j and k to page-up and page-down
" nnoremap j <C-D>
" nnoremap k <C-U>

" Default j and k to respect wrapped line content
map j gj
map k gk

" Jump around curly blocks with s
nnoremap s ]}
nnoremap S [{
vmap s ]}
vmap S [{

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

" Delete line below with <leader>d and above with <leader>D
nnoremap <silent> <leader>d :+d <CR>
nnoremap <silent> <leader>D :-d <CR>

" Move between splits with double leader
nnoremap <leader><leader>h <C-W><C-H>
nnoremap <leader><leader>j <C-W><C-J>
nnoremap <leader><leader>k <C-W><C-K>
nnoremap <leader><leader>l <C-W><C-L>

" Turn on line numbers
set number

" Make 0 go to first non-whitespace char in the line,
" and make _ do 0's original job
nnoremap 0 _
nnoremap _ 0

" Always show at least 5 lines below and above the
" cursor
set scrolloff=5

" Modify "start of line" commands to ignore leading whitespace
nnoremap 0 _
nnoremap _ 0
nnoremap I _i

" Toggle commenting of lines with <leader>/
nnoremap <leader>/ :Commentary<CR>
vnoremap <leader>/ :Commentary<CR>
" Toggle commenting of lines with command + / (only works in MacVim)
nnoremap <D-/> :Commentary<CR>
vnoremap <D-/> :Commentary<CR>

" Ignore case when searching
set ignorecase
" Don't ignore case when there _is_ a capital letter
set smartcase

" Move lines and preserve indentation
" See http://vim.wikia.com/wiki/Moving_lines_up_or_down
nnoremap <C-j> :m .+1<Return>==
nnoremap <C-k> :m .-2<Return>==
vnoremap <C-j> :m '>+1<Return>gv=gv
vnoremap <C-k> :m '<-2<Return>gv=gv

" Copy to clipboard when yanking
set clipboard=unnamed

let g:jsx_ext_required = 0          " allow JSX in .js files

" Prettier with =
nnoremap = :Prettier<CR>

" Store temp and swap files in macOS's temp directory
" This keeps working directories cleaner, but preserves vim's native
" backup functionality
" The `,.` provides the current working directory as a backup, in case
" the OS's backup directory doesn't exist
set backupdir=$TMPDIR//,.
set directory=$TMPDIR//,.
set undodir=$TMPDIR//,.

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
nmap <silent> <Leader>aj :ALENext<cr>
nmap <silent> <Leader>ak :ALEPrevious<cr>

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

" Toggle wrapping with <Leader>w
noremap <Leader>w :set wrap!<Return>

" REFERENCES
"
" https://github.com/mjackson/dotfiles/blob/master/vimrc
" https://gist.github.com/ryanflorence/6d92b7495873263aec0b4e3c299b3bd3
" https://github.com/cfoust/cawnfig/tree/master/configs/vim
"
