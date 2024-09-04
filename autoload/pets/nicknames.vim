
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

function! pets#nicknames#getnick()
    let idx = rand()%len(s:names)
    return s:names[idx]
endfunction

