if exists("g:autoloaded_splitter") || v:version < 700
    finish
endif
let g:autoloaded_splitter = 1

command! -count Split :call splitter#SplitHere(0, <count>)
command! -count Vsplit :call splitter#SplitHere(1, <count>)
