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
let g:pets#themes#imgdef#ball_image = get(g:, "pets#themes#imgdef#ball_image", expand('<sfile>:h')..'/imgdef/ball.png')

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
    let bg = [
                \ "w ",
                \ " w",
            \ ]
    return bg
endfunction

function! pets#themes#imgdef#bg_setting() abort
    highlight PetsGardenBG1 ctermfg=220 ctermbg=None guifg=#f0c050 guibg=NONE
    highlight PetsGardenBG2 ctermfg=172 ctermbg=None guifg=#e38a20 guibg=NONE
    for l in range(1, line('$'))
        if l%2
            call matchaddpos('PetsGardenBG1', [l])
        else
            call matchaddpos('PetsGardenBG2', [l])
        endif
    endfor
endfunction
