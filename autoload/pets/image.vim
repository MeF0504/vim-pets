scriptencoding utf-8

let s:iminfo = {}
let s:friend_sep = 3
let [s:max_pets, s:friend_time, s:lifetime, s:ball_max_count] =
            \ pets#main#get_defaults()

py3file <sfile>:h/image.py

function! s:set_data(img_pathes, world, name) abort
    if !has_key(s:iminfo, a:world)
        let s:iminfo[a:world] = {}
    endif
    if has_key(s:iminfo[a:world], a:name)
        return
    endif

    let res = {}
    let h = get(g:, 'pets#themes#'..a:world..'#img_height', v:null)
    if h is v:null
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
    let s:iminfo[a:world][a:name] = res
endfunction

function! pets#image#clear_iminfo()
    let s:iminfo = {}
endfunction

function! s:redraw_cb(index, timer_id) abort
    let pets = pets#main#get_config('pets')
    let opt = pets[a:index]
    if opt is v:null
        call pets#main#echo_err('failed to get pet')
        return
    endif
    let pid = opt['winID']
    let line = opt['pos'][0]
    let col = opt['pos'][1]
    let garden = pets#main#get_config('garden')
    let wrange = garden['wrange']
    let hrange = garden['hrange']
    let world = pets#main#get_config('world')
    let name = opt.name
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
    if wnext == col
        let iminfo = v:null
    elseif wnext > col
        let lr = 'r'
        let data = s:iminfo[world][name][lr]['data']->list2blob()
        let imwidth = s:iminfo[world][name][lr]['width']
        let imheight = s:iminfo[world][name][lr]['height']
        let iminfo = #{data: data, width: imwidth, height: imheight}
    else
        let lr = 'l'
        let data = s:iminfo[world][name][lr]['data']->list2blob()
        let imwidth = s:iminfo[world][name][lr]['width']
        let imheight = s:iminfo[world][name][lr]['height']
        let iminfo = #{data: data, width: imwidth, height: imheight}
    endif
    call pets#main#set_pets_opt(a:index, 'pos', [hnext, wnext])

    if has('popupwin')
        call popup_setoptions(pid, {'col': wnext, 'line': hnext, 'image': iminfo})
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
                let new_name = pets#nicknames#getnick(opt.name)
                let child_idx = pets#put_pet(opt.name, new_name)
                if child_idx == -1
                    " failed to put pet.
                    return
                endif
                call pets#main#set_pets_subopt(a:index, 'friends', child_idx, localtime())
                call pets#main#set_pets_subopt(idx, 'friends', child_idx, localtime())
                call pets#main#set_pets_subopt(child_idx, 'friends', a:index, localtime())
                call pets#main#set_pets_subopt(child_idx, 'friends', idx, localtime())
                call pets#main#set_pets_opt(child_idx, 'parents', [
                            \ pets#main#get_pet(a:index)['nickname'],
                            \ pets#main#get_pet(idx)['nickname'],
                            \ ])
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

    call s:set_data(img_pathes, world, a:name)
    let iminfo = s:iminfo[world][a:name]

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
    let tid = timer_start(1000, function(expand('<SID>').'redraw_cb', [idx]), {'repeat':-1})

    let pet_dict = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'timerID': tid,
                \ 'name': a:name,
                \ 'nickname': a:nick,
                \ 'image_pathes': img_pathes,
                \ 'pos': [h, w],
                \ 'nick_buffer': nbid,
                \ 'nick_winID': npid,
                \ 'count': 0,
                \ 'join_time': localtime(),
                \ 'friends': {},
                \ 'partner': -1,
                \ 'children': 0,
                \ 'parents': v:null,
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
    endif
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
    call pets#main#echo_msg(printf('%s(%s): %s', name, nick, nr2char(0x1f44b)))
    " remove status.
    call pets#main#rm_pets(a:index)
    " clear
endfunction

function! pets#image#throw_ball() abort
    call pets#main#echo_err('not supported.')
endfunction

