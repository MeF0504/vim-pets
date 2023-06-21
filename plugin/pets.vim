" pets
" Author: MeF0504
" License: MIT

if exists('g:loaded_pets')
  finish
endif
let g:loaded_pets = 1

if !exists('*rand')
    finish
endif
if !has('popupwin') && !has('nvim')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

let g:pets_worlds = get(g:, 'pets_worlds', [])
call add(g:pets_worlds, 'default')

function! s:pets_get_names(arglead, cmdline, cursorpos) abort
    let names = pets#get_all_pet_names()
    return filter(names, '!stridx(v:val, a:arglead)')
endfunction

command! -nargs=* -complete=customlist,s:pets_get_names Pets call pets#pets(<f-args>)
command! -nargs=1 -complete=customlist,s:pets_get_names PetsWithYou call pets#withyou#main(<f-args>)
command! PetsWithYouClose call pets#withyou#close()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
