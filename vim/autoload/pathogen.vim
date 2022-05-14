
" pathogen.vim - path option manipulation
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      2.0

" Install in ~/.vim/autoload (or ~\vimfiles\autoload).
"
" For management of individually installed plugins in ~/.vim/bundle (or
" ~\vimfiles\bundle), adding `call pathogen#infect()` to your .vimrc
" prior to `filetype plugin indent on` is the only other setup necessary.
"
" The API is documented inline below.  For maximum ease of reading,
" :set foldmethod=marker

if exists("g:loaded_pathogen") || &cp
  finish
endif
let g:loaded_pathogen = 1

" Point of entry for basic default usage.  Give a directory name to invoke
" pathogen#runtime_append_all_bundles() (defaults to "bundle"), or a full path
" to invoke pathogen#runtime_prepend_subdirectories().  Afterwards,
" pathogen#cycle_filetype() is invoked.
function! pathogen#infect(...) abort " {{{1
  let source_path = a:0 ? a:1 : 'bundle'
  if source_path =~# '[\\/]'
    call pathogen#runtime_prepend_subdirectories(source_path)
  else
    call pathogen#runtime_append_all_bundles(source_path)
  endif
  call pathogen#cycle_filetype()
endfunction " }}}1

" Split a path into a list.
function! pathogen#split(path) abort " {{{1
  if type(a:path) == type([]) | return a:path | endif
  let split = split(a:path,'\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val,''\\\([\\,]\)'',''\1'',"g")')
endfunction " }}}1

" Convert a list to a path.
function! pathogen#join(...) abort " {{{1
  if type(a:1) == type(1) && a:1
    let i = 1
    let space = ' '
  else
    let i = 0
    let space = ''
  endif
  let path = ""
  while i < a:0
    if type(a:000[i]) == type([])
      let list = a:000[i]
      let j = 0
      while j < len(list)
        let escaped = substitute(list[j],'[,'.space.']\|\\[\,'.space.']\@=','\\&','g')
        let path .= ',' . escaped
        let j += 1
      endwhile
    else
      let path .= "," . a:000[i]
    endif
    let i += 1
  endwhile
  return substitute(path,'^,','','')
endfunction " }}}1

" Convert a list to a path with escaped spaces for 'path', 'tag', etc.
function! pathogen#legacyjoin(...) abort " {{{1
  return call('pathogen#join',[1] + a:000)
endfunction " }}}1

" Remove duplicates from a list.
function! pathogen#uniq(list) abort " {{{1
  let i = 0
  let seen = {}
  while i < len(a:list)
    if (a:list[i] ==# '' && exists('empty')) || has_key(seen,a:list[i])
      call remove(a:list,i)
    elseif a:list[i] ==# ''
      let i += 1
      let empty = 1
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfunction " }}}1

" \ on Windows unless shellslash is set, / everywhere else.
function! pathogen#separator() abort " {{{1
  return !exists("+shellslash") || &shellslash ? '/' : '\'
endfunction " }}}1

" Convenience wrapper around glob() which returns a list.
function! pathogen#glob(pattern) abort " {{{1
  let files = split(glob(a:pattern),"\n")
  return map(files,'substitute(v:val,"[".pathogen#separator()."/]$","","")')
endfunction "}}}1

" Like pathogen#glob(), only limit the results to directories.
function! pathogen#glob_directories(pattern) abort " {{{1
  return filter(pathogen#glob(a:pattern),'isdirectory(v:val)')
endfunction "}}}1

" Turn filetype detection off and back on again if it was already enabled.
function! pathogen#cycle_filetype() " {{{1
  if exists('g:did_load_filetypes')
    filetype off
    filetype on
  endif
endfunction " }}}1

" Checks if a bundle is 'disabled'. A bundle is considered 'disabled' if
" its 'basename()' is included in g:pathogen_disabled[]' or ends in a tilde.