source ~/.vimrc__defaults

call plug#begin('~/.vim/plugged')
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

" Press <escape><return> or <escape><wait a second...> to clear highlighting
" of a search
" nnoremap <esc> :noh<return><esc>
" nnoremap <esc>^[ <esc>^[
set nohlsearch

" Remap j and k to page-up and page-down
nnoremap j <C-D>
nnoremap k <C-U>

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
