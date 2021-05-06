source ~/.vimrc__defaults

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins

call plug#begin('~/.vim/plugged')
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'ianks/vim-tsx'
  " Plug 'Quramy/tsuquyomi'
  Plug 'leafgarland/typescript-vim'
  Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
  Plug 'dense-analysis/ale'
  " Plug '907th/vim-auto-save'
  Plug 'kannokanno/previm'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-sensible'
  Plug 'bkad/camelcasemotion'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
call plug#end()

let g:previm_open_cmd = 'open -a "Google Chrome"'
let g:jsx_ext_required = 0 " allow JSX in .js files
let g:camelcasemotion_key = '<leader>'
let g:airline_theme='light'

autocmd FileType typescript setlocal formatprg=prettier\ --parser\ typescript

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General options

" Change the leader to space
let mapleader = "\<Space>"

" Copy to clipboard when yanking
set clipboard=unnamed

" Store temp and swap files in macOS's temp directory
" This keeps working directories cleaner, but preserves vim's native
" backup functionality
" The `,.` provides the current working directory as a backup, in case
" the OS's backup directory doesn't exist
set backupdir=$TMPDIR//,.
set directory=$TMPDIR//,.
set undodir=$TMPDIR//,.

" Add < and > to the sets of pairs that you can navigate with %
set matchpairs+=<:>

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

" Always show at least 5 lines below and above the cursor
set scrolloff=5

" Show the line and column number of the cursor position
set ruler

" Enable syntax highlighting
syntax on

" Necessary for true color support afaik
set termguicolors
set t_8f=[38;2;%lu;%lu;%lum
set t_8b=[48;2;%lu;%lu;%lum

" Turn on line numbers
set number

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text

" use tabs as spaces
set expandtab
" set number of spaces inserted when tabbing
set shiftwidth=2
" use 2 char width for tab chars
set tabstop=2

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Searching

" Don't highlight all matches of a search
" set nohlsearch

" Jump around and show matches as we search with /.
" Useful when you want to look to see if something's in
" the file but don't want to commit to jumping to it.
set incsearch
set gdefault

" Ignore case when searching
set ignorecase
" Don't ignore case when there _is_ a capital letter
set smartcase

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapping

set wrap                " wrap long lines by default
set linebreak           " when wrapping, break on word boundaries
" auto wrap text at the given number of chars
" this is 0 right now to wrap at the window width. if we want to give up on soft wrapping at some point, and just actually wrap lines at a given number of chars in the future, we can set that here
set textwidth=0
set wrapmargin=0
" This seems like the only way to softwrap at 80 chars. However, it can only do so by manually changing the size of the terminal window, which isn't ideal.
" set columns=80

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remappings  

" Swap ; and :. Because they're swapped in my global keyboard bindings, and it makese sense the way Vim originally has them
nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;

" File actions
" Ideally this would be <leader>w, but the collision with the CamelCaseMotion plugin forced my hand. So.... `s` for save it is
nnoremap <silent> <leader>s :w<CR>
nnoremap <silent> <leader>q :q<CR>
nnoremap <silent> <leader>Q :qa!<CR>
nnoremap <silent> <leader>x :x<CR>   

" Prettier with <leader>u
nnoremap <leader>u :Prettier<CR>

" Paste last yanked with <leader>p (last yanked will be in `0` register, while last yanked _or_ deleted will be in default register, `"`)
nnoremap <leader>p "0p

" Change default keybindings for moving through jump history to <C-[> and <C-]>
" (my global keyboard overrides use the defaults of <C-i> and <C-o>
" UPDATE: Because <C-[> has a special meaning (escape) in the terminal, we
" can't put this in .vimrc. Instead, we're going to use Karabiner to map this
" when in the terminal, and apply this remapping directly in any GUIs for Vim
" (e.g. VS Code)
" nnoremap <C-[> <C-o>
" nnoremap <C-]> <C-i>

" Comment lines (both in Normal and Visual Modes)
noremap <leader>c :Commentary<CR>

" Clear search highlights
noremap <leader>/ :nohl<CR>

" When making a new line with o/O, preserve indentation -- even if we escape right to Normal mode right away
nnoremap o o<space><bs>
nnoremap O O<space><bs>
 
" Change 0's and i's default behavior to go to the first non-whitespace
" character, instead of the first character, in a line
noremap 0 _
" Use _ to get back 0's native behavior
noremap _ 0
nnoremap I _i
nnoremap c0 c^
nnoremap d0 d^
" When changing a "full line", preserve indentation
nnoremap cc _C

" Change `Y` to mirror the behavior of `C` and `D` (read: operate until the end of the line)
" For some reason, `Y`'s default behavior is that of `yy`'s (yank the whole line). Discussion here: https://vi.stackexchange.com/questions/6061/why-is-y-a-synonym-for-yy-instead-of-y#:~:text=The%20command%20Y%20is%20a,duplicate%20several%20lines%20try%203YP.
nnoremap Y y$

" Remap down and up arrow keys to scroll half pages up and down
" NOTE: At the time of this writing, this actually lets us use <C-j> and <C-k> to scroll, because of our OS remappings with Karabiner
noremap <Down> <C-d>
noremap <Up> <C-u>

" Insert line below, without moving to it or entering Insert mode
nnoremap <leader>k moO<esc>`o
nnoremap <leader>j moo<esc>`o

" Insert line below and move to it, but stay in Normal mode
nnoremap <CR> o<Space><backspace><esc>

" Insert lines above/below with padding
nnoremap <leader>o o<CR><space><backspace>
nnoremap <leader>O O<space><backspace><esc>O

" Prevent `x` from writing to the default register
nnoremap x "_x
vnoremap x "_x

" Duplicate current line
nnoremap <leader>d yyp
" Duplicate visual selection _after_ the selection (by default, vim takes you back to the cursor position you started the visual selection with; so '> takes us back to the end of it before pasting)
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
vnoremap s ]}
" This might be nice at some point, but the capital S conflicts with vim-surround
nnoremap S [{

" Delete line below with <leader>d and above with <leader>D
" nnoremap <silent> <leader>d :+d <CR>
" nnoremap <silent> <leader>D :-d <CR>

" <leader>/ to clear search highlighting of a search
nnoremap <leader>/ :noh

" Toggle wrapping with <Leader>w
" noremap <Leader>w :set wrap!<Return>

" This doesn't play well with VS Code Vim right now (doesn't preserve column). Issue here: https://github.com/VSCodeVim/Vim/issues/6240
" Default j and k to respect wrapped line content
" NOTE: This used to me just `map` (for some reason…), but that had an issue where the column wasn't preserved properly when using j/k. Wow, was that the most annoying thing in the world :)
" nnoremap j gj
" nnoremap k gk


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" References

" https://github.com/mjackson/dotfiles/blob/master/vimrc
" https://gist.github.com/ryanflorence/6d92b7495873263aec0b4e3c299b3bd3
" https://github.com/cfoust/cawnfig/tree/master/configs/vim
