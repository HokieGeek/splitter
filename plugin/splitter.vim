command! -count Split :call splitter#SplitHere(0, <count>)
command! -count Vsplit :call splitter#SplitHere(1, <count>)
