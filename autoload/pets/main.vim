scriptencoding utf-8

function! s:get_config(var_name, default) abort
    if exists(printf("g:pets#%s#%s", s:pets_status.world, a:var_name))
        return eval(printf("g:pets#%s#%s", s:pets_status.world, a:var_name))
    else
        return get(g:, printf("pets_%s", a:var_name), a:default)
    endif
endfunction

function! s:bg_setting() abort
    if exists(printf('*pets#%s#bg_setting', s:pets_status.world))
        execute printf('call pets#%s#bg_setting()', s:pets_status.world)
    endif
endfunction

function! s:get_bg(height, width) abort
    let world = s:pets_status.world
    let bg = eval(printf('pets#%s#get_bg()', world))
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

function! pets#main#echo_err(str) abort
    echohl ErrorMsg
    echo a:str
    echohl None
endfunction

function! pets#main#echo_msg(msg) abort
    if !has_key(s:pets_status, 'messages')
        let s:pets_status.messages = []
    endif
    let time = strftime('[%b-%d %H:%M:%S]  ')
    call add(s:pets_status.messages, time..a:msg)
    echo a:msg
endfunction

function! pets#main#start_pets_timer() abort
    if has_key(s:pets_status, 'pets')
        for i in keys(s:pets_status.pets)
            if has_key(s:pets_status.pets[i], 'timerID')
                " already started
            else
                let tid = timer_start(1000, function(expand('<SID>').'pets_cb', [i]), {'repeat':-1})
                let s:pets_status.pets[i]['timerID'] = tid
            endif
        endfor
    endif
endfunction

function! pets#main#stop_pets_timer() abort
    if has_key(s:pets_status, 'pets')
        for i in keys(s:pets_status.pets)
            if has_key(s:pets_status.pets[i], 'timerID')
                let tid =  s:pets_status.pets[i]['timerID']
                call timer_stop(tid)
                call remove(s:pets_status.pets[i], 'timerID')
            endif
        endfor
    endif
endfunction

function! pets#main#create_garden() abort
    if has_key(s:pets_status, 'garden')
        call pets#main#echo_err('garden is already created.')
        return v:false
    endif

    " set configure
    let width = s:get_config('garden_width', &columns/2)
    let height = s:get_config('garden_height', &lines/3)
    let pos = s:get_config('garden_pos', [&lines-&cmdheight-1, &columns-1, 'botright'])
    let bg = s:get_bg(height, width)
    let lifetime_enable = s:get_config('lifetime_enable', 1)
    let birth_enable = s:get_config('birth_enable', 1)
    let shownn = get(g:, 'pets_shownn', v:false)
    let bimg = s:get_config('ball_image', nr2char(0x26bd))

    if pos[2][:2] == 'bot'
        let cur_h = pos[0]
    elseif pos[2][:2] == 'top'
        let cur_h = &lines-pos[0]
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return v:false
    endif
    if height > cur_h
        call pets#main#echo_err(printf('garden requires height %d (current: %d)', height, cur_h))
        return v:false
    endif

     let [bid, pid] = s:float_open(bg, pos[0], pos[1], 'Normal', 48,
                \ pos[2], width, height, 1)
     call win_execute(pid, printf('call %sbg_setting()', expand('<SID>')))

    if pos[2][-4:] == 'left'
        let l = pos[1]
        let r = l+width
    elseif pos[2][-5:] == 'right'
        let r = pos[1]
        let l = r-width
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return
    endif
    let wran = [l+1, r-1]

    if pos[2][:2] == 'top'
        let t = pos[0]
        let b = t+height
    elseif pos[2][:2] == 'bot'
        let b = pos[0]
        let t = b-height
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return
    endif
    let hran = [t+1, b-1]

    let s:pets_status.garden = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'width': width,
                \ 'height': height,
                \ 'pos': pos,
                \ 'wrange': wran,
                \ 'hrange': hran,
                \ 'tab': tabpagenr(),
                \ 'lifetime': lifetime_enable,
                \ 'birth': birth_enable,
                \ 'max_pets': s:max_pets,
                \ 'shownn': shownn,
                \ 'ball_image': bimg,
                \ }
    return v:true
endfunction

