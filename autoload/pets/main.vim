scriptencoding utf-8

let s:pets_status = {}
let s:max_pets = 5
let s:friend_time = 30 " sec
let s:lifetime = 10*60 " sec
let s:ball_max_count = 12  " 12*400/1000 sec
let s:friend_sep = 3
let s:curdir = expand('<sfile>:h')

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

function! pets#main#rm_config(key) abort
    call remove(s:pets_status, a:key)
endfunction

function! pets#main#rm_pets(idx)
    if !has_key(s:pets_status.pets, a:idx)
        call pets#main#log(printf('%d is already removed', a:idx))
        return -1
    endif
    call remove(s:pets_status.pets, a:idx)
endfunction

function! s:set_garden_opt(opt, val) abort
    let s:pets_status.garden[a:opt] = a:val
endfunction

" function! pets#main#get_pet(idx) abort
"     if !has_key(s:pets_status.pets, a:idx)
"         call pets#main#log(printf('failed to get pet: %d', a:idx))
"         return v:null
"     endif
"     return s:pets_status.pets[a:idx]
" endfunction

function! s:set_pets_opt(idx, opt, val) abort
    if !has_key(s:pets_status.pets, a:idx)
        call pets#main#log(printf('failed to set pet opt: %d, %s, %s',
                    \ a:idx, opt, execute('echo a:val')))
        return -1
    endif
    let s:pets_status.pets[a:idx][a:opt] = a:val
endfunction

function! s:set_pets_subopt(idx, opt1, opt2, val) abort
    if !has_key(s:pets_status.pets, a:idx)
        call pets#main#log(printf('failed to set pet subopt: %d, %s, %s',
                    \ a:idx, a:opt1, execute('echo a:val')))
        return -1
    endif
    let s:pets_status.pets[a:idx][a:opt1][a:opt2] = a:val
endfunction

function! s:set_ball_opt(opt, val) abort
    let s:pets_status.ball[a:opt] = a:val
endfunction

function! s:set_ball_subopt(opt1, opt2, val) abort
    let s:pets_status.ball[a:opt1][a:opt2] = a:val
endfunction

" function! pets#main#rm_pets_opt(idx, opt)
"     if !has_key(s:pets_status.pets, a:idx)
"         call pets#main#log(printf('%d is already removed (opt:%s)', a:idx, a:opt))
"         return -1
"     endif
"     call remove(s:pets_status.pets[a:idx], a:opt)
" endfunction

function! s:rm_pets_subopt(idx, opt1, opt2)
    if !has_key(s:pets_status.pets, a:idx)
        call pets#main#log(printf('%d is already removed (subopt:%s)', a:idx, a:opt))
        return -1
    endif
    call remove(s:pets_status.pets[a:idx][a:opt1], a:opt2)
endfunction

function! pets#main#float(
            \ text, line, col,
            \ highlight, zindex,
            \ pos, width, height, border,
            \ image,
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

    if a:image isnot v:null
        if has('nvim')
            let im_config = a:image
        else
            let [data, imwidth, imheight] = a:image
            let im_config = #{data: data->list2blob(),
                        \ width: imwidth, height: imheight}
        endif
    else
        let im_config = v:null
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
                    \ 'image': im_config,
                    \ }
        let pid = popup_create(text, popup_option)

    elseif has('nvim')
        if im_config is v:null
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
        else
            let h = 2
            let w = h/2.0*im_config[1]/im_config[2]
            " echomsg printf('%f, %f, %f, %f', h, w, im_config[1], im_config[2])
            let pid = v:lua.require'vim-pets'.set_image(im_config[0],
                        \ a:line, a:col, h, w)
                        " \ a:line, a:col, im_config[1], im_config[2])
        endif
    endif

    return [bid, pid]
endfunction

function! pets#main#close_float(pid) abort
    if has('popupwin')
        if match(popup_list(), printf("^%d$", a:pid)) != -1
            call popup_close(a:pid)
        endif
    elseif has('nvim')
        if nvim_win_is_valid(a:pid)
            call nvim_win_close(a:pid, v:false)
        else
            call v:lua.require'vim-pets'.close(a:pid)
        endif
    endif
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

function! pets#main#log(msg) abort
    if !has_key(s:pets_status, 'log')
        let s:pets_status.log = []
    endif
    let time = strftime('[%b-%d %H:%M:%S]  ')
    call add(s:pets_status.log, time..a:msg)
endfunction

function! pets#main#showlog() abort
    if !has_key(s:pets_status, 'log')
        echo 'no log messages'
        return
    endif
    for msg in s:pets_status.log
        echo msg
    endfor
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
    if s:pets_status.type == 'image'
        let def_ball = s:curdir..'/themes/imgdef/ball.png'
    else
        let def_ball = nr2char(0x26bd)
    endif
    let bimg = s:get_config('ball_image', def_ball)
    let img_height = s:get_config('img_height', v:null)

    " check height
    if pos[2][:2] == 'bot'
        let cur_h = pos[0]
    elseif pos[2][:2] == 'top'
        let cur_h = &lines-pos[0]
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return v:false
    endif
    if height > cur_h
        call pets#main#echo_err(printf('garden height should be <= %d (current: %d)', cur_h, height))
        return v:false
    endif

    " create garden window
     let [bid, pid] = pets#main#float(bg, pos[0], pos[1], 'Normal', 48,
                \ pos[2], width, height, 1, v:null)
     call win_execute(pid, printf('call %sbg_setting()', expand('<SID>')))

     " set garden width range
    if pos[2][-4:] == 'left'
        let l = pos[1]
        let r = l+width
    elseif pos[2][-5:] == 'right'
        let r = pos[1]
        let l = r-width
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return v:false
    endif
    let wran = [l+1, r-1]

     " set garden height range
    if pos[2][:2] == 'top'
        let t = pos[0]
        let b = t+height
    elseif pos[2][:2] == 'bot'
        let b = pos[0]
        let t = b-height
    else
        call pets#main#echo_err(printf('incorrect pos setting: %s.', pos[2]))
        return v:false
    endif
    let hran = [t+1, b-1]

    " set garden status
    let s:pets_status.idx = 0
    let s:pets_status.garden = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'timerID': v:null,
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
                \ 'image_height': img_height,
                \ }
    return v:true
endfunction

function! s:pets_cb(timer_id) abort
    let pets = s:pets_status.pets
    let max_idx = max(keys(pets))
    for i in sort(keys(pets))
        let opt = pets[i]
        if opt is v:null
            call pets#main#echo_err('failed to get pet')
            continue
        endif
        let pid = opt['winID']
        let line = opt['pos'][0]
        let col = opt['pos'][1]
        let garden = s:pets_status.garden
        let wrange = garden['wrange']
        let hrange = garden['hrange']
        let world = s:pets_status.world
        let name = opt.name
        let lifetime_enable = garden.lifetime
        let birth_enable = garden.birth
        let type = s:pets_status.type

        " lifetime
        if lifetime_enable && (localtime()-opt.join_time > s:lifetime)
            call pets#leave_pet('lifetime', i)
            continue
        endif

        " move
        if hrange[0] >= line
            let hnext = line+1
        elseif hrange[1] <= line
            let hnext = line-1
        else
            let rand = rand()%100
            let ball = get(s:pets_status, 'ball', v:null)
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
            let ball = get(s:pets_status, 'ball', v:null)
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

        if type == 'emoji'
            let iminfo = v:null
        elseif wnext == col
            " 'image'
            let iminfo = v:null
        elseif wnext > col
            " 'image'
            let lr = 'r'
            let ori_info = pets#image#get_iminfo(world, name)
            if has('nvim')
                let iminfo = [ori_info[lr]['path'], hnext, wnext,
                            \ ori_info[lr]['width'], ori_info[lr]['height']]
            else
                let data = ori_info[lr]['data']->list2blob()
                let imwidth = ori_info[lr]['width']
                let imheight = ori_info[lr]['height']
                let iminfo = #{data: data, width: imwidth, height: imheight}
            endif
        else
            " 'image'
            let lr = 'l'
            let ori_info = pets#image#get_iminfo(world, name)
            if has('nvim')
                let iminfo = [ori_info[lr]['path'], hnext, wnext,
                            \ ori_info[lr]['width'], ori_info[lr]['height']]
            else
                let data = ori_info[lr]['data']->list2blob()
                let imwidth = ori_info[lr]['width']
                let imheight = ori_info[lr]['height']
                let iminfo = #{data: data, width: imwidth, height: imheight}
            endif
        endif
        call s:set_pets_opt(i, 'pos', [hnext, wnext])

        if has('popupwin')
            call popup_setoptions(pid, {'col': wnext, 'line': hnext, 'image': iminfo})
            if garden.shownn
                let npid = opt['nick_winID']
                call popup_setoptions(npid, {'col': wnext, 'line': hnext-1})
            endif
        elseif has('nvim')
            if type == 'emoji'
                call nvim_win_set_config(pid, {'relative': 'editor', 'col': wnext, 'row': hnext})
            else
                " 'image'
                call v:lua.require'vim-pets'.update_image(iminfo[0],
                            \ pid, hnext, wnext)
            endif
            if garden.shownn
                let npid = opt['nick_winID']
                call nvim_win_set_config(npid, {'relative': 'editor', 'col': wnext, 'row': hnext-1})
            endif
        endif

        for idx in range(i+1, max_idx)
            if !has_key(pets, idx)
                continue
            endif
            if match(keys(opt.friends), idx) != -1
                " already friend
                let friend = pets[idx]
                if opt.partner == -1
                    " first child
                    let is_birth = (opt.name == friend.name)
                                \ && (friend.partner == -1)
                                \ && (opt.children == 0)
                    let bias = 1/2.0
                else
                    " second child
                    let is_birth = (idx == opt.partner) && (opt.children < 2)
                    let bias = 3/4.0
                endif
                if birth_enable
                            \ && (localtime()-opt.friends[idx] >= s:lifetime*bias)
                            \ && is_birth
                    if lifetime_enable
                        call s:set_garden_opt('max_pets', garden.max_pets+1)
                    endif
                    call s:set_pets_opt(i, 'partner', idx)
                    call s:set_pets_opt(idx, 'partner', i)
                    call s:set_pets_opt(i, 'children', opt.children+1)
                    call s:set_pets_opt(idx, 'children', friend.children+1)
                    let new_name = pets#nicknames#getnick(opt.name)
                    let child_idx = pets#put_pet(opt.name, new_name)
                    if child_idx == -1
                        " failed to put pet.
                        continue
                    endif
                    call s:set_pets_subopt(i, 'friends', child_idx, localtime())
                    call s:set_pets_subopt(idx, 'friends', child_idx, localtime())
                    call s:set_pets_subopt(child_idx, 'friends', i, localtime())
                    call s:set_pets_subopt(child_idx, 'friends', idx, localtime())
                    call s:set_pets_opt(child_idx, 'parents', [i, idx])
                    call pets#main#echo_msg(printf('message: %s(%s) is born!', opt.name, new_name))
                endif
            else
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
                    call s:set_pets_subopt(i, 'friends', idx, localtime())
                    call s:set_pets_subopt(idx, 'friends', i, localtime())
                endif
            endif
        endfor
    endfor
endfunction

function! pets#main#put_pets(name, nick)
    if !has_key(s:pets_status, 'pets')
        let s:pets_status.pets = {}
    endif

    " get config
    let type = s:pets_status.type
    let world = s:pets_status.world
    let pets = s:pets_status.pets
    let garden = s:pets_status.garden
    let img = eval(printf('pets#themes#%s#get_pet("%s")', world, a:name))

    " check doublication
    for idx in keys(pets)
        let pet = pets[idx]
        if pet.name is# a:name && pet.nickname is# a:nick
            call pets#main#echo_err(printf('%s named "%s" has already joined.', a:name, a:nick))
            return -1
        endif
    endfor

    " get an image
    if type == 'image'
        for lr in keys(img)
            let ip = img[lr]
            if !filereadable(ip)
                call pets#main#echo_err(printf('file %s does not exist!', ip))
                return -1
            endif
        endfor
        let showim = ""
        if has('nvim')
            call pets#image#set_data_nvim(img, world, a:name)
            let iminfo = pets#image#get_iminfo(world, a:name)
            let iminfo = [iminfo.l.path, iminfo.l.width, iminfo.l.height]
        else
            call pets#image#set_data_vim(img, world, a:name)
            let iminfo = pets#image#get_iminfo(world, a:name)
            let iminfo = [iminfo.l.data, iminfo.l.width, iminfo.l.height]
        endif
    else
        " 'emoji'
        let showim = img
        let iminfo = v:null
    endif

    " put a pet
    let wran = garden.wrange
    let w = wran[0]+rand()%(wran[1]-wran[0])
    let hran = garden.hrange
    let h = hran[0]+rand()%(hran[1]-hran[0])
    let [bid, pid] = pets#main#float(showim, h, w, 'Normal', 49, 'botright',
                \ 2, 1, 0, iminfo)
    let idx = s:pets_status.idx
    let s:pets_status.idx += 1
    if garden.shownn
        let [nbid, npid] = pets#main#float(printf("%s", a:nick), h-1, w,
                    \ 'Normal', 49, 'botright', len(a:nick)+1, 1, 0, v:null)
    else
        let nbid = -1
        let npid = -1
    endif

    " Hey!
    call pets#main#echo_msg(printf('%s(%s): %s', a:name, a:nick, nr2char(0x1f603)))

    let pet_dict = {
                \ 'buffer': bid,
                \ 'winID': pid,
                \ 'name': a:name,
                \ 'nickname': a:nick,
                \ 'image': img,
                \ 'pos': [h, w],
                \ 'join_time': localtime(),
                \ 'friends': {},
                \ 'partner': -1,
                \ 'children': 0,
                \ 'parents': v:null,
                \ 'nick_buffer': nbid,
                \ 'nick_winID': npid,
                \ }
    let s:pets_status.pets[idx] = pet_dict
    if len(pets) > garden.max_pets
        let old_idx = min(keys(pets))
        call pets#main#leave_pet('leave', old_idx)
    endif
    return idx
endfunction

function! pets#main#set_timer() abort
    let tid = timer_start(1000, expand('<SID>').'pets_cb', {'repeat':-1})
    let s:pets_status.garden.timerID = tid
endfunction

function! pets#main#leave_pet(type, index) abort
    let garden = s:pets_status.garden
    let pets = s:pets_status.pets
    let opt = pets[a:index]
    if opt is v:null
        call pets#main#echo_err('failed to get pet')
    endif
    let name = opt['name']
    let pid = opt['winID']
    let nick = opt['nickname']
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
                call s:rm_pets_subopt(fid, 'friends', a:index)
            endfor
        endif
    endif
    " remove status.
    call pets#main#rm_pets(a:index)
endfunction

function! s:ball_cb(start_point, tid) abort
    " get config
    let ball = s:pets_status.ball
    let pid = ball['winID']
    let line = ball['pos'][0]
    let col = ball['pos'][1]
    let bcount = ball['count']
    let reflect = ball['ref']
    let garden = s:pets_status.garden
    let wrange = garden['wrange']
    let hrange = garden['hrange']
    let world = s:pets_status.world
    let type = s:pets_status.type

    if bcount >= s:ball_max_count
        call s:clean_ball()
        return
    endif

    " move
    if hrange[0] >= line
        " bottom
        let hnext = line+1
        call s:set_ball_opt('ref', !reflect)
    elseif hrange[1] <= line
        " top
        let hnext = line-1
        call s:set_ball_opt('ref', !reflect)
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
    call s:set_ball_subopt('pos', 0, hnext)

    if wrange[0] >= col
        " left side
        let wnext = col+1
        call s:set_ball_opt('ref', !reflect)
    elseif wrange[1] <= col
        " right side
        let wnext = col-1
        call s:set_ball_opt('ref', !reflect)
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
    call s:set_ball_subopt('pos', 1, wnext)

    if type == 'emoji'
        let iminfo = v:null
    else
        " 'image'
        let ori_info = pets#image#get_iminfo(world, 'ball')
        if has('nvim')
            let iminfo = [ori_info['path'], hnext, wnext,
                        \ ori_info['width'], ori_info['height']]
        else
            let data = ori_info['data']->list2blob()
            let imwidth = ori_info['width']
            let imheight = ori_info['height']
            let iminfo = #{data: data, width: imwidth, height: imheight}
        endif
    endif

    call s:set_ball_opt('count', ball.count+1)
    if has('popupwin')
        call popup_setoptions(pid, {'col': wnext, 'line': hnext, 'image': iminfo})
    elseif has('nvim')
        call nvim_win_set_config(pid, {'relative': 'editor', 'col': wnext, 'row': hnext})
    endif
endfunction

function! s:clean_ball() abort
    let ball = s:pets_status.ball
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

function! pets#main#throw_ball() abort
    " get config
    let garden = s:pets_status.garden
    let world = s:pets_status.world
    let img = garden.ball_image
    let wran = garden.wrange
    let hran = garden.hrange
    let type = s:pets_status.type
    " set starting point
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

    " get image
    if type == 'emoji'
        let iminfo = v:null
        let showim = img
    else
        " 'image'
        let showim = ""
        if !filereadable(img)
            call pets#main#echo_err(printf('file %s does not exist!', img))
            return -1
        endif
        if has('nvim')
            call pets#image#set_data_nvim(img, world, 'ball')
            let iminfo = pets#image#get_iminfo(world, 'ball')
            let iminfo = [iminfo.path, iminfo.width, iminfo.height]
        else
            call pets#image#set_data_vim(img, world, 'ball')
            let iminfo = pets#image#get_iminfo(world, 'ball')
            let iminfo = [iminfo.data, iminfo.width, iminfo.height]
        endif
    endif

    " put ball
    let [bid, pid] = pets#main#float(showim, h, w, 'Normal', 49, 'botright',
                \ 2, 1, 0, iminfo)
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
    let s:pets_status.ball = ball_dict
endfunction
