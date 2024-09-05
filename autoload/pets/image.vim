scriptencoding utf-8

" https://zenn.dev/vim_jp/articles/358848a5144b63
let s:echoraw = has('nvim')
      \ ? {str->chansend(v:stderr, str)}
      \ : {str->echoraw(str)}

function pets#image#display_sixel(path, lnum, cnum) abort
  " save cursor pos
  call s:echoraw("\x1b[s")

  " move cursor pos
  call s:echoraw($"\x1b[{a:lnum};{a:cnum}H")

  " display sixels
  call s:echoraw(system($"img2sixel {a:path}"))

  " restore cursor pos
  call s:echoraw("\x1b[u")
endfunction

" call pets#image#display_sixel('autoload/pets/themes/test_img/mef0504.jpg', 5, 10)

function! s:redraw_cb(index, timer_id) abort
    let pets = pets#main#get_config('pets')
    let opt = pets[a:index]
    let line = opt['pos'][0]
    let col = opt['pos'][1]
    let l:count = opt['count']
    call pets#main#set_pets_opt(a:index, 'count', l:count+1)
    let img_pathes = opt['image_pathes']
    let L = len(img_pathes)
    call pets#image#display_sixel(img_pathes[l:count%L], line, col)
endfunction

function! pets#image#put_pets(name, nick) abort
    if !executable('img2sixel')
        call pets#main#echo_err('To show images, img2sixel command is required.')
        return -1
    endif
    if pets#main#get_config('pets') is v:null
        call pets#main#set_opt('pets', {})
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
    call pets#main#set_opt('idx', idx+1)
    if garden.shownn
        let [nbid, npid] = pets#main#float(printf("%s", a:nick), h-1, w,
                    \ 'Normal', 49, 'botright', len(a:nick)+1, 1, 0)
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
    let pets = pets#main#get_config('pets')
    let opt = pets[a:index]
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

