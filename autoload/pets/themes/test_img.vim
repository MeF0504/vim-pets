scriptencoding utf-8

let s:pets = {
            \ 'mef0504': [
            \ expand('<sfile>:h')..'/test_img/mef0504_0.jpg',
            \ expand('<sfile>:h')..'/test_img/mef0504_1.jpg',
            \ expand('<sfile>:h')..'/test_img/mef0504_2.jpg',
            \ expand('<sfile>:h')..'/test_img/mef0504_3.jpg',
            \ ],
            \ }
let pets#themes#test_img#type = 'image'

function! pets#themes#test_img#get_pet(name) abort
    if !has_key(s:pets, a:name)
        echohl ErrorMsg
        echo printf('"%s" is not in this world.', a:name)
        echohl None
        return ""
    endif

    return s:pets[a:name]
endfunction

function! pets#themes#test_img#get_pet_names() abort
    return keys(s:pets)
endfunction

function! pets#themes#test_img#get_bg() abort
    return [' ']
endfunction

