set nocompatible
let mapleader = " "
set number
set ruler
set encoding=utf-8
set wrap
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set laststatus=2
set showcmd
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set syntax=on
map <leader><space> :let @/=''<cr> " clear search
nmap <Tab> :bn<CR>
nmap <S-Tab> :bp<CR>
nmap <leader>x :bd<CR>
