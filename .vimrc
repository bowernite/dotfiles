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

" use tabs as spaces
set expandtab
" set number of spaces inserted when tabbing
set shiftwidth=2


