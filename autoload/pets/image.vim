scriptencoding utf-8

let s:iminfo = {}

py3file <sfile>:h/image.py

function! pets#image#set_data(img_pathes, world, name) abort
    if !has_key(s:iminfo, a:world)
        let s:iminfo[a:world] = {}
    endif
    if has_key(s:iminfo[a:world], a:name)
        return
    endif

    let h = get(g:, 'pets#themes#'..a:world..'#img_height', v:null)
    if h is v:null
        let h = get(g:, 'pets_img_height', v:null)
    endif
    let res = {}

    if a:name == 'ball'
        let h = float2nr(h/1.5)
        let fname = fnamemodify(a:img_pathes, ':t:r')
        python3 convert_image(vim.eval('a:img_pathes'), vim.eval('h'))
        let res['data'] = eval(printf('pets#image#%s_data', fname))
        let res['height'] = eval(printf('pets#image#%s_h', fname))
        let res['width'] = eval(printf('pets#image#%s_w', fname))
        let s:iminfo[a:world]['ball'] = res
        return
    endif

    for lr in ['l', 'r']
        let res[lr] = {}
        let fname = fnamemodify(a:img_pathes[lr], ':t:r')
        python3 convert_image(vim.eval('a:img_pathes[lr]'), vim.eval('h'))
        let res[lr]['data'] = eval(printf('pets#image#%s_data', fname))
        let res[lr]['height'] = eval(printf('pets#image#%s_h', fname))
        let res[lr]['width'] = eval(printf('pets#image#%s_w', fname))
    endfor
    let s:iminfo[a:world][a:name] = res
endfunction

function! pets#image#get_iminfo(world, name) abort
    return s:iminfo[a:world][a:name]
endfunction

function! pets#image#clear_iminfo() abort
    let s:iminfo = {}
endfunction
