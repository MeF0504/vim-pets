
let s:names = [
            \ "Mugi",
            \ "Leo",
            \ "Luna",
            \ "Sora",
            \ "Bella",
            \ "Coco",
            \ "Mocha",
            \ "Max",
            \ "Charie",
            \ "Snoopy",
            \ ]
let s:name_cnt = {}

" thks https://interuniversitylearning.com/archives/4575
function! s:arabic2roman(num) abort
    let val = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
    let syb = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
    let roman_num = ''
    let num = a:num
    let i = 0
    while num > 0
        for x in range(num / val[i])
            let roman_num .= syb[i]
            let num -= val[i]
        endfor
        let i += 1
    endwhile
    return roman_num
endfunction

function! pets#nicknames#getnick(name)
    let nick = s:names[rand()%len(s:names)]
    if has_key(s:name_cnt, a:name)
        if has_key(s:name_cnt[a:name], nick)
            let s:name_cnt[a:name][nick] += 1
            let nick = printf('%s-%s', nick, 
                        \ s:arabic2roman(s:name_cnt[a:name][nick])
                        \ )
        else
            let s:name_cnt[a:name][nick] = 0
        endif
    else
        let s:name_cnt[a:name] = {}
        let s:name_cnt[a:name][nick] = 0
    endif
    return nick
endfunction

function! pets#nicknames#init()
    let s:name_cnt = {}
endfunction

