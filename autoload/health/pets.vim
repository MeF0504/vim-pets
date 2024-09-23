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
    " check sixel
    if executable('img2sixel')
        call s:report_ok('img2sixel is executable.')
    else
        call s:report_warn('img2sixel is not executable. Showing image mode is not available.')
    endif
endfunction

