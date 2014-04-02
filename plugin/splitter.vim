if exists("g:autoloaded_splitter") || v:version < 700
    finish
endif
let g:autoloaded_splitter = 1

if !exists("g:splitter_split_window_size_horizontal")
    let g:splitter_split_window_size_horizontal= 10
endif
if !exists("g:splitter_split_window_size_vertical")
    let g:splitter_split_window_size_vertical= 50
endif

command! -count Split :call splitter#SplitHere(0, <count>)
command! -count Vsplit :call splitter#SplitHere(1, <count>)

command! -bar -bang -nargs=* Run :call splitter#RunCommandHandler(<bang>0, 1, <f-args>)
command! -bar -bang -nargs=* RunIn :call splitter#RunCommandHandler(<bang>0, 0, <f-args>)

command! -bar Log :call splitter#OpenLog()
