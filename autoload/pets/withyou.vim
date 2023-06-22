scriptencoding utf-8

let s:pids = []
let s:tids = []
let s:count = 0
const s:bias = 3

function! s:float_cursor_open(img) abort
    let pid = -1
    let bid = -1
    let shift = 1+s:bias*s:count+localtime()%2
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
    let [bid, pid] = s:float_cursor_open(img)
    let tid = timer_start(100, function(expand('<SID>').'cursor_cb', [pid, s:count]), {'repeat':-1})
    let s:pids = add(s:pids, pid)
    let s:count += 1
    let s:tids = add(s:tids, tid)
endfunction

function! pets#withyou#close() abort
    for tid in s:tids
        cal timer_stop(tid)
    endfor
    for pid in s:pids
        if has('popupwin')
            call popup_close(pid)
        elseif has('nvim')
            call nvim_win_close(pid, v:false)
        endif
    endfor
    let s:count = 0
    let s:pids = []
    let s:tids = []
endfunction

