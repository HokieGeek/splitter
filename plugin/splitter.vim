if exists("g:autoloaded_splitter") || v:version < 700
    finish
endif
let g:autoloaded_splitter = 1

if !exists("g:splitter_split_window_size")
    let g:splitter_split_window_size = 10
endif

command! -count Split :call splitter#SplitHere(0, <count>)
command! -count Vsplit :call splitter#SplitHere(1, <count>)

command! -bang -nargs=* Run :call splitter#CommandHandler(<bang>0, 1, <f-args>)
command! -bang -nargs=* RunIn :call splitter#CommandHandler(<bang>0, 0, <f-args>)
