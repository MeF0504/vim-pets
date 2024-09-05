scriptencoding utf-8

let s:pets_status = {}
let s:max_pets = 5
let s:friend_time = 30 " sec
let s:lifetime = 10*60 " sec
let s:ball_max_count = 12  " 12*400/1000 sec

" check status
function! pets#main#status() abort
    if has_key(s:pets_status, 'world')
        echohl Special
        echo 'world: '
        echohl Title
        echon s:pets_status.world
        echohl None
    endif
    if has_key(s:pets_status, 'type')
        echohl Special
        echo 'type: '
        echohl Title
        echon s:pets_status.type
        echohl None
    endif
    if has_key(s:pets_status, 'garden')
        echohl Special
        echo 'garden;'
        for k in keys(s:pets_status.garden)
            echohl Identifier
            echo k
            echohl None
            echon ': '
            echon s:pets_status.garden[k]
        endfor
    endif
    if has_key(s:pets_status, 'pets')
        echohl Special
        echo 'pets;'
        for i in keys(s:pets_status.pets)
            echohl Special
            echo i
            for k in keys(s:pets_status.pets[i])
                echohl Identifier
                echo k
                echohl None
                echon ': '
                echon s:pets_status.pets[i][k]
            endfor
        endfor
        echohl None
    endif
    if has_key(s:pets_status, 'ball')
        echohl Special
        echo 'ball;'
        for k in keys(s:pets_status.ball)
            echohl Identifier
            echo k
            echohl None
            echon ': '
            echon s:pets_status.ball[k]
        endfor
    endif
    if has_key(s:pets_status, 'messages')
        echohl Special
        echo 'messages;'
        echohl None
        for msg in s:pets_status.messages
            echo msg
        endfor
    endif
    echohl None
endfunction

function! pets#main#get_config(key) abort
    if has_key(s:pets_status, a:key)
        return s:pets_status[a:key]
    else
        return v:null
    endif
endfunction

function! pets#main#set_config(sec, val) abort
    let s:pets_status[a:sec] = a:val
endfunction

function! pets#main#init_pet(idx, dict) abort
    let s:pets_status.pets[a:idx] = a:dict
endfunction

function! pets#main#set_garden_opt(opt, val) abort
    let s:pets_status.garden[a:opt] = a:val
endfunction

function! pets#main#set_pets_opt(idx, opt, val) abort
    let s:pets_status.pets[a:idx][a:opt] = a:val
endfunction

function! pets#main#set_pets_subopt(idx, opt1, opt2, val) abort
    let s:pets_status.pets[a:idx][a:opt1][a:opt2] = a:val
endfunction

function! pets#main#set_ball_opt(opt, val) abort
    let s:pets_status.ball[a:opt] = a:val
endfunction

function! pets#main#set_ball_subopt(opt1, opt2, val) abort
    let s:pets_status.ball[a:opt1][a:opt2] = a:val
endfunction

function! pets#main#rm_config(key) abort
    call remove(s:pets_status, a:key)
endfunction

function! pets#main#rm_pets(idx)
    call remove(s:pets_status.pets, a:idx)
endfunction

function! pets#main#rm_pets_opt(idx, opt)
    call remove(s:pets_status.pets[a:idx], a:opt)
endfunction

function! pets#main#rm_pets_subopt(idx, opt1, opt2)
    call remove(s:pets_status.pets[a:idx][a:opt1], a:opt2)
endfunction

function! pets#main#float(
            \ text, line, col,
            \ highlight, zindex,
            \ pos, width, height, border,
            \ ) abort
    let pid = 0
    let bid = 0
    if type(a:text) == type([])
        let text = a:text
    else
        let text = [a:text]
    endif
    if has_key(s:pets_status, 'garden')
        let tabnr = s:pets_status.garden.tab
    else
        let tabnr = 0  " current tab
    endif

    if has('popupwin')
        if a:border
            let border = []
        else
            let border = ['', '', '', '']
        endif
        let popup_option = {
                    \ 'line': a:line,
                    \ 'col': a:col,
                    \ 'drag': v:false,
                    \ 'dragall': v:false,
                    \ 'resize': v:false,
                    \ 'close': 'none',
                    \ 'highlight': a:highlight,
                    \ 'scrollbar': v:false,
                    \ 'zindex': a:zindex,
                    \ 'maxwidth': a:width,
                    \ 'maxheight': a:height,
                    \ 'pos': a:pos,
                    \ 'border': border,
                    \ 'tabpage': tabnr,
                    \ }
        let pid = popup_create(text, popup_option)

    elseif has('nvim')
        if a:pos == 'topright'
            let anc = 'NE'
        elseif a:pos == 'topleft'
            let anc = 'NW'
        elseif a:pos == 'botright'
            let anc = 'SE'
        elseif a:pos == 'botleft'
            let anc = 'SW'
        endif
        if a:border
            let border = 'double'
        else
            let border = 'none'
        endif
        let popup_option = {
                    \ 'relative': 'editor',
                    \ 'row': a:line,
                    \ 'col': a:col,
                    \ 'style': 'minimal',
                    \ 'width': a:width,
                    \ 'height': a:height,
                    \ 'anchor': anc,
                    \ 'border': border,
                    \ 'focusable': v:false,
                    \ 'zindex': a:zindex,
                    \ }

        let bid = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(bid, 0, -1, 0, text)
        let pid = nvim_open_win(bid, v:false, popup_option)
        call win_execute(pid, "setlocal winhighlight=Normal:".a:highlight)
    endif

    return [bid, pid]
endfunction

function! pets#main#close_float(pid) abort
    if win_id2tabwin(a:pid) != [0, 0]
        if has('popupwin')
            call popup_close(a:pid)
        elseif has('nvim')
            call nvim_win_close(a:pid, v:false)
        endif
    endif
endfunction

function! pets#main#get_defaults() abort
    return [s:max_pets, s:friend_time, s:lifetime, s:ball_max_count]
endfunction

function! s:get_config(var_name, default) abort
    if exists(printf("g:pets#themes#%s#%s", s:pets_status.world, a:var_name))
        return eval(printf("g:pets#themes#%s#%s", s:pets_status.world, a:var_name))
    else
        return get(g:, printf("pets_%s", a:var_name), a:default)
    endif
endfunction

function! s:bg_setting() abort
    if exists(printf('*pets#themes#%s#bg_setting', s:pets_status.world))
        execute printf('call pets#themes#%s#bg_setting()', s:pets_status.world)
    endif
endfunction

function! s:get_bg(height, width) abort
    let world = s:pets_status.world
    let bg = eval(printf('pets#themes#%s#get_bg()', world))
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

function! pets#main#create_garden() abort
    if has_key(s:pets_status, 'garden')
        call pets#main#echo_err('garden is already created. do not create.')
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

     let [bid, pid] = pets#main#float(bg, pos[0], pos[1], 'Normal', 48,
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

    let s:pets_status.idx = 0
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

