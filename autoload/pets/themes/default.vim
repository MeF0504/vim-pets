scriptencoding utf-8

let s:pets = {
            \ 'dog': nr2char(0x1f415),
            \ 'cat': nr2char(0x1f408),
            \ 'rabbit': nr2char(0x1f407),
            \ 't-rex': nr2char(0x1f996),
            \ }
" 🐕, 🐈, 🐇, 🦖
let pets#themes#default#type = 'emoji'

function! pets#themes#default#get_pet(name) abort
    if !has_key(s:pets, a:name)
        echohl ErrorMsg
        echo printf('"%s" is not in this world.', a:name)
        echohl None
        return ""
    endif

    return s:pets[a:name]
endfunction

function! pets#themes#default#get_pet_names() abort
    return keys(s:pets)
endfunction

function! pets#themes#default#get_bg() abort
    let bg = [
                \ "v ",
                \ " v",
            \ ]
    return bg
endfunction

function! pets#themes#default#bg_setting() abort
    highlight PetsGardenBG1 ctermfg=28 ctermbg=None guifg=#309030 guibg=NONE
    highlight PetsGardenBG2 ctermfg=22 ctermbg=None guifg=#285528 guibg=NONE
    for l in range(1, line('$'))
        if l%2
            call matchaddpos('PetsGardenBG1', [l])
        else
            call matchaddpos('PetsGardenBG2', [l])
        endif
    endfor
endfunction

