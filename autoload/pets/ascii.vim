
let s:pets = {
            \ 'dog': "🐕",
            \ 'cat': "🐈",
            \ 'rabbit': "🐇",
            \ 't-rex': "🦖",
            \ }
" 1f415
" 1f408
" 1f407
" 1f996
function! pets#ascii#get_pet(name) abort
    if !has_key(s:pets, a:name)
        echohl ErrorMsg
        echo printf('"%s" is not in this world.', a:name)
        echohl None
        return ""
    endif

    return s:pets[a:name]
endfunction

function! pets#ascii#get_pets_names() abort
    return keys(s:pets)
endfunction

let s:bgs = [
            \ [
                \ "v ",
                \ " v",
            \ ]
        \ ]

function! pets#ascii#get_bg(height, width) abort
    let bg = s:bgs[0]
    let bgh = len(bg)
    let bgw = len(bg[0])
    let res = []
    for i in range(a:height)
        call add(res, '')
    endfor
    for i in range(a:width/bgw)
        for j in range(a:height)
            let res[j] .= bg[j%bgh]
        endfor
    endfor

    for i in range(a:width%bgw)
        for j in range(a:height)
            let res[j] .= bg[j%bgh][i]
        endfor
    endfor
    return res
endfunction

