scriptencoding utf-8

let s:pets = {
            \ 'dog': nr2char(0x1f415),
            \ 'cat': nr2char(0x1f408),
            \ 'rabbit': nr2char(0x1f407),
            \ 't-rex': nr2char(0x1f996),
            \ }
" 🐕, 🐈, 🐇, 🦖
function! pets#default#get_pet(name) abort
    if !has_key(s:pets, a:name)
        echohl ErrorMsg
        echo printf('"%s" is not in this world.', a:name)
        echohl None
        return ""
    endif

    return s:pets[a:name]
endfunction

function! pets#default#get_pet_names() abort
    return keys(s:pets)
endfunction

function! pets#default#get_bg() abort
    let bg = [
                \ "v ",
                \ " v",
            \ ]
    return bg
endfunction

function! pets#default#bg_setting() abort
    highlight PetsGardenBG1 ctermfg=10 ctermbg=None guifg=Lime guibg=NONE
    highlight PetsGardenBG2 ctermfg=2 ctermbg=None guifg=Green guibg=NONE
    for l in range(1, line('$'))
        if l%2
            call matchaddpos('PetsGardenBG1', [l])
        else
            call matchaddpos('PetsGardenBG2', [l])
        endif
    endfor
endfunction

