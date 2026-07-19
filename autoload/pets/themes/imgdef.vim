scriptencoding utf-8

let s:pets = {
            \ 'imdog': #{l: expand('<sfile>:h')..'/imgdef/dog_l.png',
                       \ r: expand('<sfile>:h')..'/imgdef/dog_r.png'},
            \ 'imcat': #{l: expand('<sfile>:h')..'/imgdef/cat_l.png',
                       \ r: expand('<sfile>:h')..'/imgdef/cat_r.png'},
            \ 'imrabbit': #{l: expand('<sfile>:h')..'/imgdef/rabbit_l.png',
                          \ r: expand('<sfile>:h')..'/imgdef/rabbit_r.png'},
            \ }
let pets#themes#imgdef#type = 'image'

function! pets#themes#imgdef#get_pet(name) abort
    if !has_key(s:pets, a:name)
        echohl ErrorMsg
        echo printf('"%s" is not in this world.', a:name)
        echohl None
        return ""
    endif

    return s:pets[a:name]
endfunction

function! pets#themes#imgdef#get_pet_names() abort
    return keys(s:pets)
endfunction

function! pets#themes#imgdef#get_bg() abort
    return [' ']
endfunction

