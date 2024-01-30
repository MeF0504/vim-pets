
" background functions {{{
function! pets#get_all_pet_names() abort
    let res = []
    for wld in g:pets_worlds
        try
            let res = eval(printf('res+pets#themes#%s#get_pet_names()', wld))
        endtry
    endfor
    return res
endfunction

function! s:get_index(args)
    let pets = meflib#main#get_config('pets')
    if empty(a:args)
        let index = min(keys(pets))
    elseif has_key(pets, a:args[0])
        let index = a:args[0]
    else
        let l = strridx(a:args[0], '(')
        let r = strridx(a:args[0], ')')
        let nick = a:args[0][l+1:r-1]
        let name = a:args[0][:l-1]
        let index = -1
        for idx in keys(pets)
            let opt = pets[idx]
            if opt.name is# name && opt.nickname is# nick
                let index = idx
                break
            endif
        endfor
    endif
    if !has_key(pets, index)
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
        let func_name = printf('pets#themes#%s#get_pet_names()', wld)
        try
            let pet_names = eval(func_name)
        catch
            let pet_names = []
        endtry
        if match(pet_names, printf('^%s$', name)) != -1
            " let s:pets_status.world = wld
            call pets#main#set_config(wld, 'world')
            call pets#main#set_config('emoji', 'type')
            break
        endif
    endfor
    " if !has_key(s:pets_status, 'world')
    if pets#main#get_config('world') is v:null
        call pets#main#echo_err("incorrect pets's name.")
        return
    endif
    let res = pets#main#create_garden()
    if res
        if a:0 >= 2
            let nick = a:2
        else
            let nick = pets#main#get_config('idx')
        endif
        call pets#put_pet(name, nick)
    endif
endfunction

function! pets#put_pet(name, ...) abort
    let garden = pets#main#get_config('garden')
    if garden is v:null
        call pets#main#echo_err('Please create garden before.')
        return -1
    endif
    if has('nvim') && garden.tab != tabpagenr()
        call pets#main#echo_err('garden is not here.')
        return -1
    endif
    if empty(a:000)
        " let nick = s:idx
        let nick = pets#main#get_config('idx')
    else
        let nick = a:1
    endif

    call call(printf('pets#%s#put_pets', pets#main#get_config('type')),
                \ [a:name, nick])
endfunction

function! pets#leave_pet(type, ...) abort
    " type: leave (PetsLeave), close (PetsClose), lifetime
    let pets = pets#main#get_config('pets')
    " if !has_key(s:pets_status, 'pets') || empty(s:pets_status.pets)
    if pets is v:null || empty(pets)
        call pets#main#echo_err('there is no pets in garden.')
        return
    endif
    let index = s:get_index(a:000)
    if index == -1
        return
    endif
    call call(printf('pets#%s#leave_pet', pets#main#get_config('type')),
                \ [a:type, index])
endfunction

function! pets#close()
    " clear pets
    let pets = pets#main#get_config('pets')
    " if has_key(s:pets_status, 'pets')
    if !(pets is v:null)
        for idx in keys(pets)
            call pets#leave_pet('close', idx)
        endfor
        " call remove(s:pets_status, 'pets')
        call pets#main#rm_config('pets')
    endif

    " clear garden
    let garden = pets#main#get_config('garden')
    " if has_key(s:pets_status, 'garden')
    if !(garden is v:null)
        let pid = garden.winID
        if has('popupwin')
            call popup_close(pid)
        elseif has('nvim')
            call nvim_win_close(pid, v:false)
        endif
        " call remove(s:pets_status, 'garden')
        call pets#main#rm_config('garden')
    endif

    " clear messages
    " if has_key(s:pets_status, 'messages')
    if !(pets#main#get_config('messages') is v:null)
        " call remove(s:pets_status, 'messages')
        call pets#main#rm_config('messages')
    endif

    " clear index
    if !(pets#main#get_config('idx') is v:null)
        call pets#main#rm_config('idx')
    endif

    " clear world's name
    " if has_key(s:pets_status, 'world')
    if !(pets#main#get_config('world') is v:null)
        " call remove(s:pets_status, 'world')
        call pets#main#rm_config('world')
    endif
endfunction

function! pets#throw_ball() abort
    let garden = pets#main#get_config('garden')
    " if !has_key(s:pets_status, 'garden')
    if garden is v:null
        call pets#main#echo_err('Please create garden before.')
        return
    endif
    if garden.tab != tabpagenr()
        call pets#main#echo_err('garden is not here.')
        return
    endif

    " if has_key(s:pets_status, 'ball')
    if !pets#main#get_config('ball') is v:null
        return
    endif

    call call(printf('pets#%s#throw_ball', pets#main#get_config('type')), [])
endfunction

function! pets#message_log() abort
    let message = pets#main#get_config('message')
    " if has_key(s:pets_status, 'messages')
    if !(message is v:null)
        for msg in messages
            echo msg
        endfor
    endif
endfunction

" commands
function! s:pets_get_names(arglead, cmdline, cursorpos) abort
    let names = eval(printf('pets#themes#%s#get_pet_names()',
                \ pets#main#get_config('world')))
    return filter(names, '!stridx(v:val, a:arglead)')
endfunction

function! s:pets_select_leave_pets(arglead, cmdline, cursorpos) abort
    let res = []
    let pets = pets#main#get_config('pets')
    for idx in keys(pets)
        let opt = pets[idx]
        call add(res, printf('%s(%s)', opt.name, opt.nickname))
    endfor
    return filter(res, '!stridx(v:val, a:arglead)')
endfunction

command! -nargs=+ -complete=customlist,s:pets_get_names PetsJoin call pets#put_pet(<f-args>)
command! -nargs=? -complete=customlist,s:pets_select_leave_pets PetsLeave call pets#leave_pet('leave', <f-args>)
command! PetsClose call pets#close()
command! PetsMessages call pets#message_log()
command! PetsThrowBall call pets#throw_ball()

