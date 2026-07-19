scriptencoding utf-8

py3file <sfile>:h/image.py

" https://zenn.dev/vim_jp/articles/358848a5144b63
" let s:echoraw = has('nvim')
"       \ ? {str->chansend(v:stderr, str)}
"       \ : {str->echoraw(str)}

" function pets#image#display_sixel(path, lnum, cnum) abort
"   " save cursor pos
"   if !filereadable(a:path)
"       call pets#main#log(printf('image file is not found, %s', a:path))
"   endif
"   call s:echoraw("\x1b[s")

"   " move cursor pos
"   call s:echoraw($"\x1b[{a:lnum};{a:cnum}H")

"   " display sixels
"   call s:echoraw(system($"img2sixel {a:path}"))

"   " restore cursor pos
"   call s:echoraw("\x1b[u")
" endfunction

function! s:set_data(img_pathes, world) abort
    let res = {}
    let h = get(g:, 'pets#themes#'..a:world..'#img_height', v:null)
    if h == v:null
        let h = get(g:, 'pets_img_height', v:null)
    endif
    for lr in ['l', 'r']
        let res[lr] = {}
        let fname = fnamemodify(a:img_pathes[lr], ':t:r')
        python3 convert_image(vim.eval('a:img_pathes[lr]'), vim.eval('h'))
        let res[lr]['data'] = eval(printf('pets#image#%s_data', fname))
        let res[lr]['height'] = eval(printf('pets#image#%s_h', fname))
        let res[lr]['width'] = eval(printf('pets#image#%s_w', fname))
    endfor
    return res
endfunction

function! s:redraw_cb(index, timer_id) abort
    let opt = pets#main#get_pet(a:index)
    if opt is v:null
        call pets#main#echo_err('failed to get pet')
        return
    endif
    let line = opt['pos'][0]
    let col = opt['pos'][1]
    let l:count = opt['count']
    call pets#main#set_pets_opt(a:index, 'count', l:count+1)
    let img_pathes = opt['image_pathes']
    let L = len(img_pathes)
    call pets#image#display_sixel(img_pathes[l:count%L], line, col)
endfunction

function! pets#image#put_pets(name, nick) abort
    if pets#main#get_config('pets') is v:null
        call pets#main#set_config('pets', {})
    endif

    let world = pets#main#get_config('world')
    let pets = pets#main#get_config('pets')
    let garden = pets#main#get_config('garden')
    let img_pathes = eval(printf('pets#themes#%s#get_pet("%s")', world, a:name))
    if empty(img_pathes)
        return -1
    endif

    for lr in keys(img_pathes)
        let ip = img_pathes[lr]
        if !filereadable(ip)
            call pets#main#echo_err(printf('file %s does not exist!', ip))
            return -1
        endif
    endfor

    for idx in keys(pets)
        let pet = pets[idx]
        if pet.name is# a:name && pet.nickname is# a:nick
            call pets#main#echo_err(printf('%s named "%s" has already joined.', a:name, a:nick))
            return -1
        endif
    endfor

    let iminfo = s:set_data(img_pathes, world)

    let wran = garden.wrange
    let w = wran[0]+rand()%(wran[1]-wran[0])
    let hran = garden.hrange
    let h = hran[0]+rand()%(hran[1]-hran[0])
    " call pets#image#display_sixel(img_pathes[0], h, w)
    let [bid, pid] = pets#main#float("", h, w, 'Normal', 49, 'botright',
                \ 1, 1, 0,
                \ [iminfo['l']['data'], iminfo['l']['width'], iminfo['l']['height']])
    let idx = pets#main#get_config('idx')
    call pets#main#set_config('idx', idx+1)
    if garden.shownn
        let [nbid, npid] = pets#main#float(printf("%s", a:nick), h-1, w,
                    \ 'Normal', 49, 'botright', len(a:nick)+1, 1, 0, v:null)
    else
        let nbid = -1
        let npid = -1
    endif

    " Hey!
    call pets#main#echo_msg(printf('%s(%s): %s', a:name, a:nick, nr2char(0x1f603)))
    " let tid = timer_start(1000, function(expand('<SID>').'redraw_cb', [idx]), {'repeat':-1})
    let tid = 0

    let pet_dict = {
                \ 'timerID': tid,
                \ 'name': a:name,
                \ 'nickname': a:nick,
                \ 'image_pathes': img_pathes,
                \ 'pos': [h, w],
                \ 'nick_buffer': nbid,
                \ 'nick_winID': npid,
                \ 'count': 0,
                \ 'join_time': localtime(),
                \ }
    call pets#main#init_pet(idx, pet_dict)
    if len(pets) > garden.max_pets
        let old_idx = min(keys(pets))
        call pets#image#leave_pet('leave', old_idx)
    endif
    return idx
endfunction

function! pets#image#__put_pets(name, nick) abort
    if !executable('img2sixel')
        call pets#main#echo_err('To show images, img2sixel command is required.')
        return -1
    endif
    if pets#main#get_config('pets') is v:null
        call pets#main#set_config('pets', {})
    endif

    let world = pets#main#get_config('world')
    let pets = pets#main#get_config('pets')
    let garden = pets#main#get_config('garden')
    let img_pathes = eval(printf('pets#themes#%s#get_pet("%s")', world, a:name))
    if empty(img_pathes)
        return -1
    endif
    for ip in img_pathes
        if !filereadable(ip)
            call pets#main#echo_err(printf('file %s does not exist!', ip))
            return -1
        endif
    endfor

    for idx in keys(pets)
        let pet = pets[idx]
        if pet.name is# a:name && pet.nickname is# a:nick
            call pets#main#echo_err(printf('%s named "%s" has already joined.', a:name, a:nick))
            return -1
        endif
    endfor

    let wran = garden.wrange
    let w = wran[0]+rand()%(wran[1]-wran[0])
    let hran = garden.hrange
    let h = hran[0]+rand()%(hran[1]-hran[0])
    " call pets#image#display_sixel(img_pathes[0], h, w)
    let idx = pets#main#get_config('idx')
    call pets#main#set_config('idx', idx+1)
    if garden.shownn
        let [nbid, npid] = pets#main#float(printf("%s", a:nick), h-1, w,
                    \ 'Normal', 49, 'botright', len(a:nick)+1, 1, 0, v:null)
    else
        let nbid = -1
        let npid = -1
    endif

    " Hey!
    call pets#main#echo_msg(printf('%s(%s): %s', a:name, a:nick, nr2char(0x1f603)))
    let tid = timer_start(1000, function(expand('<SID>').'redraw_cb', [idx]), {'repeat':-1})

    let pet_dict = {
                \ 'timerID': tid,
                \ 'name': a:name,
                \ 'nickname': a:nick,
                \ 'image_pathes': img_pathes,
                \ 'pos': [h, w],
                \ 'nick_buffer': nbid,
                \ 'nick_winID': npid,
                \ 'count': 0,
                \ 'join_time': localtime(),
                \ }
    call pets#main#init_pet(idx, pet_dict)
    if len(pets) > garden.max_pets
        let old_idx = min(keys(pets))
        call pets#image#leave_pet('leave', old_idx)
    endif
    return idx
endfunction

function! pets#image#leave_pet(type, index) abort
    let garden = pets#main#get_config('garden')
    let opt = pets#main#get_pet(a:index)
    if opt is v:null
        call pets#main#echo_err('failed to get pet')
        " clear
        execute "normal! \<c-l>"
        return
    endif
    let name = opt['name']
    let nick = opt['nickname']
    " stop timer function.
    call timer_stop(opt['timerID'])
    " close floating/popup window.
    if garden.shownn
        let npid = opt['nick_winID']
        call pets#main#close_float(npid)
    endif
    " say bye.
    call pets#main#echo_msg(printf('%s(%s): %s', name, nick, nr2char(0x1f44b)))
    " remove status.
    call pets#main#rm_pets(a:index)
    " clear
    execute "normal! \<c-l>"
endfunction

function! pets#image#throw_ball() abort
    call pets#main#echo_err('not supported.')
endfunction

