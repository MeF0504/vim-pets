scriptencoding utf-8

let s:friend_sep = 3
let [s:max_pets, s:friend_time, s:lifetime, s:ball_max_count] =
            \ pets#main#get_defaults()

function! pets#emoji#start_pets_timer() abort
    let pets = pets#main#get_config('pets')
    if !(pets is v:null)
        for i in keys(pets)
            if has_key(pets[i], 'timerID')
                " already started
            else
                let tid = timer_start(1000, function(expand('<SID>').'pets_cb', [i]), {'repeat':-1})
                let pets[i]['timerID'] = tid
            endif
        endfor
    endif
endfunction

function! pets#emoji#stop_pets_timer() abort
    let pets = pets#main#get_config('pets')
    if !(pets is v:null)
        for i in keys(pets)
            if has_key(pets[i], 'timerID')
                let tid =  pets[i]['timerID']
                call timer_stop(tid)
                call remove(pets[i], 'timerID')
            endif
        endfor
    endif
endfunction

function! <SID>pets_cb(index, timer_id) abort
    let pets = pets#main#get_config('pets')
    let opt = pets[a:index]
    let pid = opt['winID']
    let line = opt['pos'][0]
    let col = opt['pos'][1]
    let garden = pets#main#get_config('garden')
    let wrange = garden['wrange']
    let hrange = garden['hrange']
    let lifetime_enable = garden.lifetime
    let birth_enable = garden.birth

    " lifetime
    if lifetime_enable && (localtime()-opt.join_time > s:lifetime)
        call pets#leave_pet('lifetime', a:index)
        return
    endif

    " move
    if hrange[0] >= line
        let hnext = line+1
    elseif hrange[1] <= line
        let hnext = line-1
    else
        let rand = rand()%100
        let ball = pets#main#get_config('ball')
        if !(ball is v:null)
            if ball.pos[0] == line
                let hnext = line
            elseif ball.pos[0] > line
                let hnext = line+1
            else
                let hnext = line-1
            endif
        elseif rand >= 60
            let hnext = line+1
        elseif rand >= 40
            let hnext = line
        else
            let hnext = line-1
        endif
    endif

    if wrange[0] >= col
        let wnext = col+1
    elseif wrange[1] <= col
        let wnext = col-1
    else
        let rand = rand()%100
        let ball = pets#main#get_config('ball')
        if !(ball is v:null)
            if ball.pos[1] == col
                let wnext = col
            elseif ball.pos[1] > col
                let wnext = col+1
            else
                let wnext = col-1
            endif
        elseif rand >= 60
            let wnext = col+1
        elseif rand >= 40
            let wnext = col
        else
            let wnext = col-1
        endif
    endif
    call pets#main#set_pets_opt(a:index, 'pos', [hnext, wnext])

    if has('popupwin')
        call popup_setoptions(pid, {'col': wnext, 'line': hnext})
        if garden.shownn
            let npid = opt['nick_winID']
            call popup_setoptions(npid, {'col': wnext, 'line': hnext-1})
        endif
    elseif has('nvim')
        call nvim_win_set_config(pid, {'relative': 'editor', 'col': wnext, 'row': hnext})
        if garden.shownn
            let npid = opt['nick_winID']
            call nvim_win_set_config(npid, {'relative': 'editor', 'col': wnext, 'row': hnext-1})
        endif
    endif

    for idx in keys(pets)
        if idx == a:index
            " myself
            continue
        endif
        if match(keys(opt.friends), idx) != -1
            " already friend
            if !has_key(pets, idx)
                " suppress error message
                call pets#main#log(printf('skip check friend 1, %d', idx))
                continue
            endif
            let friend = pets[idx]
            if opt.partner == -1
                " first child
                let is_birth = (opt.name == friend.name)
                            \ && (friend.partner == -1)
                            \ && (opt.children == 0)
                let bias = 1/2.0
            else
                " second child
                let is_birth = (idx == opt.partner)
                            \ && (opt.children < 2)
                let bias = 3/4.0
            endif
            if birth_enable
                        \ && (localtime()-opt.friends[idx] >= s:lifetime*bias)
                        \ && is_birth
                if lifetime_enable
                    call pets#main#set_garden_opt('max_pets', garden.max_pets+1)
                endif
                call pets#main#set_pets_opt(a:index, 'partner', idx)
                call pets#main#set_pets_opt(idx, 'partner', a:index)
                call pets#main#set_pets_opt(a:index, 'children', opt.children+1)
                call pets#main#set_pets_opt(idx, 'children', friend.children+1)
                let new_name = a:index..idx..'Jr'..opt.children
                let child_idx = pets#put_pet(opt.name, new_name)
                if child_idx == -1
                    " failed to put pet.
                    return
                endif
                call pets#main#set_pets_subopt(a:index, 'friends', child_idx, localtime())
                call pets#main#set_pets_subopt(idx, 'friends', child_idx, localtime())
                call pets#main#set_pets_subopt(child_idx, 'friends', a:index, localtime())
                call pets#main#set_pets_subopt(child_idx, 'friends', idx, localtime())
                call pets#main#echo_msg(printf('message: %s(%s) is born!', opt.name, new_name))
            endif
        else
            if !has_key(pets, idx)
                " suppress error message
                call pets#main#log(printf('skip check friend 2, %d', idx))
                continue
            endif
            let join_time = max([pets[idx].join_time, opt.join_time])
            let is_time = localtime()-join_time >= s:friend_time
            let is_sep = abs(opt.pos[0]-pets[idx].pos[0]) <= s:friend_sep
                        \ && abs(opt.pos[1]-pets[idx].pos[1]) <= s:friend_sep
            if is_time && is_sep
                " friends
                call pets#main#echo_msg(printf('%s(%s) and %s(%s) are friends: %s',
                            \ opt.name, opt.nickname,
                            \ pets[idx].name, pets[idx].nickname,
                            \ nr2char(0x1f60a)))
                call pets#main#set_pets_subopt(a:index, 'friends', idx, localtime())
                call pets#main#set_pets_subopt(idx, 'friends', a:index, localtime())
            endif
        endif
    endfor
endfunction

function! pets#emoji#put_pets(name, nick)
    if pets#main#get_config('pets') is v:null
        call pets#main#set_config('pets', {})
    endif

    let world = pets#main#get_config('world')
    let pets = pets#main#get_config('pets')
    let garden = pets#main#get_config('garden')
    let img = eval(printf('pets#themes#%s#get_pet("%s")', world, a:name))
    if empty(img)
        return -1
    endif

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
    let [bid, pid] = pets#main#float(img, h, w, 'Normal', 49, 'botright', 2, 1, 0)
    let idx = pets#main#get_config('idx')
    call pets#main#set_config('idx', idx+1)
    if garden.shownn
        let [nbid, npid] = pets#main#float(printf("%s", a:nick), h-1, w,
                    \ 'Normal', 49, 'botright', len(a:nick)+1, 1, 0)
    else
        let nbid = -1
        let npid = -1
    endif

    " Hey!
    call pets#main#echo_msg(printf('%s(%s): %s', a:name, a:nick, nr2char(0x1f603)))
    let tid = timer_start(1000, function(expand('<SID>').'pets_cb', [idx]), {'repeat':-1})

    let pet_dict = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'timerID': tid,
                \ 'name': a:name,
                \ 'nickname': a:nick,
                \ 'image': img,
                \ 'pos': [h, w],
                \ 'join_time': localtime(),
                \ 'friends': {},
                \ 'partner': -1,
                \ 'children': 0,
                \ 'nick_buffer': nbid,
                \ 'nick_winID': npid,
                \ }
    call pets#main#init_pet(idx, pet_dict)
    if len(pets) > garden.max_pets
        let old_idx = min(keys(pets))
        call pets#emoji#leave_pet('leave', old_idx)
    endif
    return idx
endfunction

function! pets#emoji#leave_pet(type, index) abort
    let garden = pets#main#get_config('garden')
    let pets = pets#main#get_config('pets')
    let opt = pets[a:index]
    let name = opt['name']
    let pid = opt['winID']
    let nick = opt['nickname']
    " stop timer function.
    call timer_stop(opt['timerID'])
    " close floating/popup window.
    call pets#main#close_float(pid)
    if garden.shownn
        let npid = opt['nick_winID']
        call pets#main#close_float(npid)
    endif
    " say bye.
    if a:type == 'lifetime'
        call pets#main#echo_msg(printf('message: %s(%s) is gone.', name, nick))
        for fid in keys(opt.friends)
            if !has_key(pets, fid)
                call pets#main#log(printf('skip say bye 1, %d', fid))
                continue
            endif
            let friend = pets[fid]
            " loss
            call pets#main#echo_msg(printf('%s(%s) -> %s(%s): %s',
                        \ friend.name, friend.nickname, name, nick,
                        \ nr2char(0x1f622)))
            call remove(friend.friends, a:index)
        endfor
    else
        " Bye
        call pets#main#echo_msg(printf('%s(%s): %s', name, nick, nr2char(0x1f44b)))
        if a:type == 'leave'
            for fid in keys(opt.friends)
                if !has_key(pets, fid)
                    call pets#main#log(printf('skip say bye 2, %d', fid))
                    continue
                endif
                let friend = pets[fid]
                " Bye
                call pets#main#echo_msg(printf('%s(%s) -> %s(%s): %s',
                            \ friend.name, friend.nickname, name, nick,
                            \ nr2char(0x1f44b)))
                call pets#main#rm_pets_subopt(fid, 'friends', a:index)
            endfor
        endif
    endif
    " remove status.
    call pets#main#rm_pets(a:index)
endfunction

function! s:ball_cb(start_point, tid) abort
    let ball = pets#main#get_config('ball')
    let pid = ball['winID']
    let line = ball['pos'][0]
    let col = ball['pos'][1]
    let bcount = ball['count']
    let reflect = ball['ref']
    let garden = pets#main#get_config('garden')
    let wrange = garden['wrange']
    let hrange = garden['hrange']

    if bcount >= s:ball_max_count
        call s:clean_ball()
        return
    endif

    if hrange[0] >= line
        " bottom
        let hnext = line+1
        call pets#main#set_ball_opt('ref', !reflect)
    elseif hrange[1] <= line
        " top
        let hnext = line-1
        call pets#main#set_ball_opt('ref', !reflect)
    else
        if a:start_point == 0
            let hnext = bcount%2==0 ? line+1 : line-1
        elseif a:start_point == 1
            if reflect
                let hnext = line+1
            else
                let hnext = line-1
            endif
        else
            let hnext = bcount%2==0 ? line+1 : line-1
        endif
    endif
    call pets#main#set_ball_subopt('pos', 0, hnext)

    if wrange[0] >= col
        " left side
        let wnext = col+1
        call pets#main#set_ball_opt('ref', !reflect)
    elseif wrange[1] <= col
        " right side
        let wnext = col-1
        call pets#main#set_ball_opt('ref', !reflect)
    else
        if a:start_point == 0
            if reflect
                let wnext = col-1
            else
                let wnext = col+1
            endif
        elseif a:start_point == 1
            let wnext = bcount%2==0 ? col+1 : col-1
        else
            if reflect
                let wnext = col+1
            else
                let wnext = col-1
            endif
        endif
    endif
    call pets#main#set_ball_subopt('pos', 1, wnext)

    call pets#main#set_ball_opt('count', ball.count+1)
    if has('popupwin')
        call popup_setoptions(pid, {'col': wnext, 'line': hnext})
    elseif has('nvim')
        call nvim_win_set_config(pid, {'relative': 'editor', 'col': wnext, 'row': hnext})
    endif
endfunction

function! s:clean_ball() abort
    let ball = pets#main#get_config('ball')
    if ball is v:null
        return
    endif
    let opt = ball
    let pid = opt['winID']
    let tid = opt['timerID']
    call timer_stop(tid)
    call pets#main#close_float(pid)
    call pets#main#rm_config('ball')
endfunction

function! pets#emoji#throw_ball() abort
    let garden = pets#main#get_config('garden')
    let img = garden.ball_image
    let wran = garden.wrange
    let hran = garden.hrange
    let start_point = rand()%3
    if start_point == 0
        " left side
        let w = wran[0]+1
        let h = hran[1]+(hran[0]-hran[1])*2/3
    elseif start_point == 1
        " bottom
        let w = (wran[0]+wran[1])/2
        let h = hran[1]-1
    else
        " right side
        let w = wran[1]-1
        let h = hran[1]+(hran[0]-hran[1])/3
    endif
    let [bid, pid] = pets#main#float(img, h, w, 'Normal', 49, 'botright', 2, 1, 0)
    " 時間間隔は1秒の約数じゃないほうが良さそう
    let tid = timer_start(400, function(expand('<SID>').'ball_cb', [start_point]), {'repeat':-1})

    let ball_dict = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'timerID': tid,
                \ 'image': img,
                \ 'pos': [h, w],
                \ 'count': 0,
                \ 'ref': v:false,
                \ }
    call pets#main#set_config('ball', ball_dict)
endfunction

