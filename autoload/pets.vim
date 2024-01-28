
let s:pets_status = {}
let s:max_pets = 5
let s:idx = 0
let s:friend_time = 30 " sec
let s:friend_sep = 3
let s:lifetime = 10*60 " sec
let s:ball_max_count = 12  " 12*400/1000 sec

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
" }}}

" background functions {{{
function! pets#get_all_pet_names() abort
    let res = []
    for wld in g:pets_worlds
        try
            let res = eval(printf('res+pets#%s#get_pet_names()', wld))
        endtry
    endfor
    return res
endfunction

function! s:get_index(args)
    if empty(a:args)
        let index = min(keys(s:pets_status.pets))
    elseif has_key(s:pets_status.pets, a:args[0])
        let index = a:args[0]
    else
        let l = strridx(a:args[0], '(')
        let r = strridx(a:args[0], ')')
        let nick = a:args[0][l+1:r-1]
        let name = a:args[0][:l-1]
        let index = -1
        for idx in keys(s:pets_status.pets)
            let opt = s:pets_status.pets[idx]
            if opt.name is# name && opt.nickname is# nick
                let index = idx
                break
            endif
        endfor
    endif
    if !has_key(s:pets_status.pets, index)
        call pets#main#echo_err('incorrect pet name or something.')
        return -1
    endif
    return index
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
        if match(pet_names, printf('^%s$', name)) != -1
            let s:pets_status.world = wld
            break
        endif
    endfor
    if !has_key(s:pets_status, 'world')
        call pets#main#echo_err("incorrect pets's name.")
        return
    endif
    let res = pets#main#create_garden()
    if res
        if a:0 >= 2
            let nick = a:2
        else
            let nick = s:idx
        endif
        call pets#put_pet(name, nick)
    endif
endfunction

function! pets#put_pet(name, ...) abort
    if !has_key(s:pets_status, 'garden')
        call pets#main#echo_err('Please create garden before.')
        return -1
    endif
    if has('nvim') && s:pets_status.garden.tab != tabpagenr()
        call pets#main#echo_err('garden is not here.')
        return -1
    endif
    call call(printf('pets#%s#put_pets', s:pets_status.type),
                \ [a:name]+a:000)
endfunction

function! pets#leave_pet(type, ...) abort
    " type: leave (PetsLeave), close (PetsClose), lifetime
    if !has_key(s:pets_status, 'pets') || empty(s:pets_status.pets)
        call pets#main#echo_err('there is no pets in garden.')
        return
    endif
    let index = s:get_index(a:000)
    if index == -1
        return
    endif
    call call(printf('pets#%s#leave_pet', s:pets_status.type),
                \ [a:type]+a:000)
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

function! pets#throw_ball() abort
    if !has_key(s:pets_status, 'garden')
        call pets#main#echo_err('Please create garden before.')
        return
    endif
    if s:pets_status.garden.tab != tabpagenr()
        call pets#main#echo_err('garden is not here.')
        return
    endif

    if has_key(s:pets_status, 'ball')
        return
    endif

    call call(printf('pets#%s#throw_ball', s:pets_status.type))
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
command! PetsThrowBall call pets#throw_ball()

