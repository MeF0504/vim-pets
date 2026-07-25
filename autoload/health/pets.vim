scriptencoding utf-8

if has('nvim-0.10')
    function! s:report_info(msg) abort
        call v:lua.vim.health.info(a:msg)
    endfunction
    function! s:report_ok(msg) abort
        call v:lua.vim.health.ok(a:msg)
    endfunction
    function! s:report_warn(msg) abort
        call v:lua.vim.health.warn(a:msg)
    endfunction
    function! s:report_error(msg) abort
        call v:lua.vim.health.error(a:msg)
    endfunction
else
    function! s:report_info(msg) abort
        call health#report_info(a:msg)
    endfunction
    function! s:report_ok(msg) abort
        call health#report_ok(a:msg)
    endfunction
    function! s:report_warn(msg) abort
        call health#report_warn(a:msg)
    endfunction
    function! s:report_error(msg) abort
        call health#report_error(a:msg)
    endfunction
endif

function! health#pets#check() abort
    " check rand()
    if exists('*rand')
        call s:report_ok('rand() is callable.')
    else
        call s:report_error('rand() is not callable.')
    endif
    " check floating/popup window
    if has('nvim')
        if exists('*nvim_open_win')
            call s:report_ok('nvim_open_win() is callable.')
        else
            call s:report_error('nvim_open_win() is not callable.')
        endif
    else
        if has('popupwin')
            call s:report_ok('popup window is available.')
        else
            call s:report_error('popup window is not available.')
        endif
    endif
    " check image support
    let im_sup = v:true
    if has('nvim')
        " image is not support yet.
    else
        if !has('image')
            call s:report_warn('+image is not supported.')
            let im_sup = v:false
        endif
        if !has('python3')
            call s:report_warn('python3 is not supported.')
            let im_sup = v:false
        endif
        if im_sup
            call s:report_ok('image type is available.')
        else
            s:report_warn('image type is not available.')
        endif
    endif
endfunction

