scriptencoding utf-8

let s:withu_status = []
let s:count = 0
const s:bias = 3

function! pets#withyou#status() abort
    for stat in s:withu_status
        echo stat
    endfor
endfunction

function! s:float_cursor_open(img, count) abort
    let pid = -1
    let bid = -1
    let shift = 1+s:bias*a:count+localtime()%2
    if has('popupwin')
        let config = {
                    \ 'line': 'cursor',
                    \ 'col': printf('cursor+%d', shift),
                    \ 'pos': 'topleft',
                    \ }
        let pid = popup_create([a:img], config)
    elseif has('nvim')
        let config = {
                    \ 'relative': 'cursor',
                    \ 'row': 0,
                    \ 'col': shift,
                    \ 'style': 'minimal',
                    \ 'width': 2,
                    \ 'height': 1,
                    \ 'anchor': 'NW',
                    \ 'border': 'none',
                    \ }
        let bid = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(bid, 0, -1, 0, [a:img])
        let pid = nvim_open_win(bid, v:false, config)
    endif
    return [bid, pid]
endfunction

function! s:cursor_cb(pid, count, tid) abort
    let shift = 1+s:bias*a:count+localtime()%2
    if has('popupwin')
        call popup_setoptions(a:pid, {
                    \ 'col': printf('cursor+%d', shift),
                    \ 'line': 'cursor',
                    \ })
    elseif has('nvim')
        call nvim_win_set_config(a:pid, {
                    \ 'relative': 'cursor',
                    \ 'col': shift, 'row': 0})
    endif
endfunction

function! pets#withyou#main(name) abort
    let world = ""
    for wld in g:pets_worlds
        let pet_names = eval(printf('pets#%s#get_pet_names()', wld))
        if match(pet_names, a:name) != -1
            let world = wld
            break
        endif
    endfor
    if empty(world)
        return
    endif
    let img = eval(printf('pets#%s#get_pet("%s")', world, a:name))
    let [bid, pid] = s:float_cursor_open(img, s:count)
    let tid = timer_start(100, function(expand('<SID>').'cursor_cb', [pid, s:count]), {'repeat':-1})


    if empty(s:withu_status)
        augroup PetsWithYou
            autocmd TabEnter * call s:pets_with_you_update()
        augroup END
    endif

    let status = {}
    let status.name = a:name
    let status.img = img
    let status.pid = pid
    let status.tid = tid
    let status.count = s:count
    call add(s:withu_status, status)
    let s:count += 1
endfunction

function! s:pets_with_you_update() abort
    for stat in s:withu_status
        if has('popupwin')
            call popup_close(stat.pid)
        elseif has('nvim')
            call nvim_win_close(stat.pid, v:false)
        endif
        call timer_stop(stat.tid)

        let [bid, pid] = s:float_cursor_open(stat.img, stat.count)
        let stat.pid = pid
        let tid = timer_start(100, function(expand('<SID>').'cursor_cb', [pid, stat.count]), {'repeat':-1})
        let stat.tid = tid
    endfor
endfunction

function! pets#withyou#close() abort
    for stat in s:withu_status
        if has('popupwin')
            call popup_close(stat.pid)
        elseif has('nvim')
            call nvim_win_close(stat.pid, v:false)
        endif
        call timer_stop(stat.tid)
    endfor
    let s:withu_status = []
    let s:count = 0
    augroup PetsWithYou
        autocmd!
    augroup END
endfunction

