
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

function! pets#nicknames#getnick(name)
    let nick = s:names[rand()%len(s:names)]
    if has_key(s:name_cnt, a:name)
        if has_key(s:name_cnt[a:name], nick)
            let s:name_cnt[a:name][nick] += 1
            let nick = printf('%s-%d', nick, s:name_cnt[a:name][nick])
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

