
let s:pets_status = {}
let s:max_pets = 5
let s:idx = 0
let s:friend_time = 30 " sec
let s:friend_sep = 3
let s:lifetime = 10*60 " sec
let g:pets_worlds = get(g:, 'pets_worlds', [])
call add(g:pets_worlds, 'default')

" check status {{{
function! pets#status() abort
    if has_key(s:pets_status, 'world')
        echohl Special
        echo 'world: '
        echohl Title
        echon s:pets_status.world
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
" }}}

" setting functions {{{
" function! s:set_pet_col() abort
"     " highlight PetsBG ctermbg=0 ctermfg=fg guibg=Black guifg=fg
" endfunction

function! s:bg_setting() abort
    if exists(printf('*pets#%s#bg_setting', s:pets_status.world))
        execute printf('call pets#%s#bg_setting()', s:pets_status.world)
    endif
endfunction
" }}}

" background functions {{{
function! s:float_open(
            \ text,
            \ line, col,
            \ highlight,
            \ zindex,
            \ pos, width, height,
            \ border,
            \ ) abort
    let pid = 0
    let bid = 0
    if type(a:text) == type([])
        let text = a:text
    else
        let text = [a:text]
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

function! s:echo_err(str) abort
    echohl ErrorMsg
    echo a:str
    echohl None
endfunction

function! pets#get_all_pet_names() abort
    let res = []
    for wld in g:pets_worlds
        try
            let res = eval(printf('res+pets#%s#get_pet_names()', wld))
        endtry
    endfor
    return res
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

function! s:echo_msg(msg) abort
    if !has_key(s:pets_status, 'messages')
        let s:pets_status.messages = []
    endif
    let time = strftime('[%b-%d %H:%M:%S]  ')
    call add(s:pets_status.messages, time..a:msg)
    echo a:msg
endfunction
" }}}

" main functions
function! pets#pets(...) abort
    if !empty(a:000)
        let name = a:1
    else
        let name = get(g:, 'pets_default_pet', 'dog')
    endif
    for wld in g:pets_worlds
        let pet_names = eval(printf('pets#%s#get_pet_names()', wld))
        if match(pet_names, name) != -1
            let s:pets_status.world = wld
            break
        endif
    endfor
    if !has_key(s:pets_status, 'world')
        call s:echo_err("incorrect pets's name.")
        return
    endif
    let res = pets#create_garden()
    if res
        if a:0 >= 2
            let nick = a:2
        else
            let nick = s:idx
        endif
        call pets#put_pet(name, nick)
    endif
endfunction

function! pets#create_garden() abort
    if has_key(s:pets_status, 'garden')
        call s:echo_err('garden is already created.')
        return v:false
    endif

    " set configure
    let width = get(g:, 'pets_garden_width', &columns/2)
    let height = get(g:, 'pets_garden_height', &lines/3)
    let pos = get(g:, 'pets_garden_pos', [&lines-&cmdheight-1, &columns-1, 'botright'])
    let bg = s:get_bg(height, width)
    let lifetime_enable = get(g:, 'pets_lifetime_enable', 1)
    let birth_enable = get(g:, 'pets_birth_enable', 1)

    if pos[2][:2] == 'bot'
        let cur_h = pos[0]
    elseif pos[2][:2] == 'top'
        let cur_h = &lines-pos[0]
    else
        call s:echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return v:false
    endif
    if height > cur_h
        call s:echo_err(printf('garden requires height %d (current: %d)', height, cur_h))
        return v:false
    endif

     let [bid, pid] = s:float_open(bg, pos[0], pos[1], 'Normal', 98,
                \ pos[2], width, height, 1)
     call win_execute(pid, printf('call %sbg_setting()', expand('<SID>')))

    if pos[2][-4:] == 'left'
        let l = pos[1]
        let r = l+width
    elseif pos[2][-5:] == 'right'
        let r = pos[1]
        let l = r-width
    else
        call s:echo_err(printf('incorrect pos setting: %s.', pos[2]))
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
        call s:echo_err(printf('incorrect pos setting: %s.', pos[2]))
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
                \ }
    return v:true
endfunction

function! pets#put_pet(name, ...) abort
    if !has_key(s:pets_status, 'garden')
        call s:echo_err('Please create garden before.')
        return
    endif
    if s:pets_status.garden.tab != tabpagenr()
        call s:echo_err('garden is not here.')
        return
    endif
    if empty(a:000)
        let nick = s:idx
    else
        let nick = a:1
    endif

    if !has_key(s:pets_status, 'pets')
        let s:pets_status.pets = {}
    endif

    let img = eval(printf('pets#%s#get_pet("%s")', s:pets_status.world, a:name))
    if empty(img)
        return
    endif

    let wran = s:pets_status.garden.wrange
    let w = wran[0]+rand()%(wran[1]-wran[0])
    let hran = s:pets_status.garden.hrange
    let h = hran[0]+rand()%(hran[1]-hran[0])
    let [bid, pid] = s:float_open(img, h, w, 'Normal', 99, 'botright', 2, 1, 0)
    let idx = s:idx
    let s:idx += 1

    call s:echo_msg(printf('%s(%s): "Hey!"', a:name, nick))
    let tid = timer_start(1000, function(expand('<SID>').'pets_cb', [idx]), {'repeat':-1})

    let pet_dict = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'timerID': tid,
                \ 'name': a:name,
                \ 'nickname': nick,
                \ 'image': img,
                \ 'pos': [h, w],
                \ 'join_time': localtime(),
                \ 'friends': {},
                \ 'is_parent': v:false,
                \ }
    let s:pets_status.pets[idx] = pet_dict
    if len(s:pets_status.pets) > s:max_pets
        let idx = min(keys(s:pets_status.pets))
        call pets#leave_pet('leave', idx)
    endif
endfunction

function! pets#leave_pet(type, ...) abort
    " type: leave (PetsLeave), close (PetsClose), lifetime
    if !has_key(s:pets_status, 'pets') || empty(s:pets_status.pets)
        call s:echo_err('there is no pets in garden.')
        return
    endif

    if empty(a:000)
        let index = min(keys(s:pets_status.pets))
    elseif has_key(s:pets_status.pets, a:1)
        let index = a:1
    else
        let l = strridx(a:1, '(')
        let r = strridx(a:1, ')')
        let nick = a:1[l+1:r-1]
        let name = a:1[:l-1]
        let index = -1
        for idx in keys(s:pets_status.pets)
            let opt = s:pets_status.pets[idx]
            if opt.name == name && opt.nickname == nick
                let index = idx
                break
            endif
        endfor
    endif
    if !has_key(s:pets_status.pets, index)
        call echo_err('incorrect pet name or something.')
        return
    endif

    let opt = s:pets_status.pets[index]
    let name = opt['name']
    let pid = opt['winID']
    let nick = opt['nickname']
    " stop timer function.
    call timer_stop(s:pets_status.pets[index]['timerID'])
    " close floating/popup window.
    if has('popupwin')
        call popup_close(pid)
    elseif has('nvim')
        call nvim_win_close(pid, v:false)
    endif
    " say bye.
    if a:type == 'lifetime'
        call s:echo_msg(printf('message: %s(%s) is gone.', name, nick))
        for fid in keys(opt.friends)
            let friend = s:pets_status.pets[fid]
            call s:echo_msg(printf('%s(%s): "Sorry for your loss, %s(%s)."', friend.name, friend.nickname, name, nick))
            call remove(friend.friends, index)
        endfor
    else
        call s:echo_msg(printf('%s(%s): "Bye!"', name, nick))
        if a:type == 'leave'
            for fid in keys(opt.friends)
                let friend = s:pets_status.pets[fid]
                call s:echo_msg(printf('%s(%s): "Bye, %s(%s)!"', friend.name, friend.nickname, name, nick))
                call remove(friend.friends, index)
            endfor
        endif
    endif
    " remove status.
    call remove(s:pets_status.pets, index)
endfunction

function! <SID>pets_cb(index, timer_id) abort
    let pets = s:pets_status.pets
    let opt = pets[a:index]
    let pid = opt['winID']
    let line = opt['pos'][0]
    let col = opt['pos'][1]
    let garden = s:pets_status.garden
    let wrange = garden['wrange']
    let hrange = garden['hrange']
    let lifetime_enable = s:pets_status.garden.lifetime
    let birth_enable = s:pets_status.garden.birth

    if lifetime_enable && (localtime()-opt.join_time > s:lifetime)
        call pets#leave_pet('lifetime', a:index)
        return
    endif

    if hrange[0] >= line
        let hnext = line+1
    elseif hrange[1] <= line
        let hnext = line-1
    else
        let rand = rand()%100
        if rand >= 60
            let hnext = line+1
        elseif rand >= 40
            let hnext = line
        else
            let hnext = line-1
        endif
    endif
    let s:pets_status.pets[a:index]['pos'][0] = hnext

    if wrange[0] >= col
        let wnext = col+1
    elseif wrange[1] <= col
        let wnext = col-1
    else
        let rand = rand()%100
        if rand >= 60
            let wnext = col+1
        elseif rand >= 40
            let wnext = col
        else
            let wnext = col-1
        endif
    endif
    let s:pets_status.pets[a:index]['pos'][1] = wnext

    if has('popupwin')
        call popup_setoptions(pid, {'col': wnext, 'line': hnext})
    elseif has('nvim')
        call nvim_win_set_config(pid, {'relative': 'editor', 'col': wnext, 'row': hnext})
    endif

    for idx in keys(pets)
        if idx == a:index
            continue
        endif
        if match(keys(opt.friends), idx) != -1
            " already friend
            let friend = s:pets_status.pets[idx]
            if birth_enable && (localtime()-opt.friends[idx] >= s:lifetime/2)
                        \ && opt.name == friend.name
                        \ && !opt.is_parent
                        \ && !friend.is_parent
                if lifetime_enable
                    let s:max_pets += 1
                endif
                let new_name = opt.nickname[:1]..friend.nickname[:1]..'Jr'
                call pets#put_pet(opt.name, new_name)
                call s:echo_msg(printf('message: %s(%s) is born!', opt.name, new_name))
                let opt.is_parent = v:true
                let friend.is_parent = v:true
            endif
        else
            let join_time = max([pets[idx].join_time, opt.join_time])
            let is_time = localtime()-join_time >= s:friend_time
            let is_sep = abs(opt.pos[0]-pets[idx].pos[0]) <= s:friend_sep
                        \ && abs(opt.pos[1]-pets[idx].pos[1]) <= s:friend_sep
            if is_time && is_sep
                call s:echo_msg(printf('%s(%s) and %s(%s): "We are friends!"',
                            \ opt.name, opt.nickname, pets[idx].name, pets[idx].nickname))
                let opt.friends[idx] = localtime()
                let pets[idx].friends[a:index] = localtime()
            endif
        endif
    endfor
endfunction

function! pets#close()
    " clear pets
    if has_key(s:pets_status, 'pets')
        for idx in keys(s:pets_status.pets)
            call pets#leave_pet('close', idx)
        endfor
        call remove(s:pets_status, 'pets')
    endif

    " clear garden
    if has_key(s:pets_status, 'garden')
        let pid = s:pets_status.garden.winID
        if has('popupwin')
            call popup_close(pid)
        elseif has('nvim')
            call nvim_win_close(pid, v:false)
        endif
        call remove(s:pets_status, 'garden')
    endif

    " clear messages
    if has_key(s:pets_status, 'messages')
        call remove(s:pets_status, 'messages')
    endif

    " clear world's name
    if has_key(s:pets_status, 'world')
        call remove(s:pets_status, 'world')
    endif

    let s:idx = 0
endfunction

function! pets#message_log() abort
    if has_key(s:pets_status, 'messages')
        for msg in s:pets_status.messages
            echo msg
        endfor
    endif
endfunction

" commands
function! s:pets_get_names(arglead, cmdline, cursorpos) abort
    let names = eval(printf('pets#%s#get_pet_names()', s:pets_status.world))
    return filter(names, '!stridx(v:val, a:arglead)')
endfunction
function! s:pets_select_leave_pets(arglead, cmdline, cursorpos) abort
    let res = []
    for idx in keys(s:pets_status.pets)
        let opt = s:pets_status.pets[idx]
        call add(res, printf('%s(%s)', opt.name, opt.nickname))
    endfor
    return filter(res, '!stridx(v:val, a:arglead)')
endfunction
command! -nargs=+ -complete=customlist,s:pets_get_names PetsJoin call pets#put_pet(<f-args>)
command! -nargs=? -complete=customlist,s:pets_select_leave_pets PetsLeave call pets#leave_pet('leave', <f-args>)
command! PetsClose call pets#close()
command! PetsMessages call pets#message_log()

" call s:set_pet_col()
" augroup Pets
"     autocmd!
"     autocmd ColorScheme * call s:set_pet_col()
" augroup END
