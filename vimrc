" set up pathogen, https://github.com/tpope/vim-pathogen
filetype on " without this vim emits a zero exit status, later, because of :ft off
filetype off
call pathogen#infect()
filetype plugin indent on

" don't bother with vi compatibility
set n