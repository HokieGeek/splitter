if exists("g:loaded_splitter") || v:version < 700
    finish
endif
let g:loaded_splitter = 1

" Open terminal {{{
function! splitter#TmuxSplitHere(vertical, size)
    let l:cmd = "tmux split-window"
    if !exists("g:splitter_tmux_version")
        let g:splitter_tmux_version = str2nr(system("tmux -V  | awk '{ print $2 }' | sed 's/[a-z]//'"))
    endif
    if g:splitter_tmux_version > 1.4
        let l:cmd .= " -c ".expand("%:p:h")
    endif
    if (a:vertical == 1)
        let l:cmd .= " -h"
    endif
    if (a:size > 0)
        let l:cmd .= ((a:vertical == 1) ? " -p " : " -l ").a:size
    endif
    call system(l:cmd)
endfunction

function! splitter#ScreenSplitHere(vertical, size)
    let l:screen_cmd = "screen -dr ".expand("$STY")." -X"

    let l:cmd = l:screen_cmd." split ".((a:vertical == 1) ? "-v" : "")
    let l:cmd .= " && ".l:screen_cmd." focus"
    if (a:size > 0)
        let l:cmd .= " && ".l:screen_cmd." resize ".a:size
    endif
    let l:cmd .= " && ".l:screen_cmd." chdir ".expand("%:p:h")
    let l:cmd .= " && ".l:screen_cmd." screen"
    call system(l:cmd)
endfunction

function! splitter#SplitHere(vertical, size)
    if exists("$TMUX")
        call splitter#TmuxSplitHere(a:vertical, a:size)
    elseif exists("$TERM") && expand("$TERM") == "screen"
        call splitter#ScreenSplitHere(a:vertical, a:size)
    else
        echomsg "Did not find neither a tmux nor a screen session"
    endif
endfunction
" }}}

" Execute command {{{
function! splitter#OpenLog()
    if exists("b:splitter_command_log")
        let l:log = b:splitter_command_log
        new
        set modifiable
        execute "r ".l:log
        0d_
        set buftype=nofile bufhidden=wipe nomodifiable
    else
        echohl WarningMsg
        echomsg "No log found. Have you run a command?"
        echohl None
    endif
endfunction
function! splitter#ExecCmd(cmd)
    if strlen(a:cmd) > 0
        let l:pipe = (&shell =~? "csh" ? "|&" : "2>&1 |")
        let l:cmd = a:cmd." ".l:pipe." tee ".b:splitter_command_log."\""
        " echomsg l:cmd
        call system(l:cmd)
    endif
endfunction
function! splitter#LaunchCommandInTmux(loc, cmd, cfg)
    if a:cfg =~? 'split'
        let l:orientation = (a:cfg ==? "split_vertical") ? "-h" : ""
        if a:cfg ==? "split_horizontal"
            let l:split_size = "-l ".g:splitter_split_window_size_horizontal
        else
            let l:split_size = ""
        endif
        let l:cmd = "tmux split-window ".l:orientation." -d ".l:split_size." \"cd ".a:loc.";"
    elseif a:cfg ==? 'window'
        let l:title = fnamemodify(split(a:cmd)[0], ":t")
        let l:cmd = "tmux new-window -d -n 'Running ".l:title." ...' \"cd ".a:loc.";"
    endif

    if exists("l:cmd")
        let l:cmd .= a:cmd
        call splitter#ExecCmd(l:cmd)
    endif
endfunction

function! splitter#LaunchCommandInScreen(loc, cmd, cfg)
    let l:screen_cmd = "screen -dr ".expand("%STY")." -X"
    if a:cfg =~? 'split'
        let l:orientation = (a:cfg ==? "split_vertical") ? "-v" : ""
        if a:cfg ==? "split_horizontal"
            let l:split_size = "-l ".g:splitter_split_window_size_horizontal
        else
            let l:split_size = ""
        endif
        let l:cmd = l:screen_cmd." split ".l:orientation
        let l:cmd .= " && ".l:screen_cmd." focus"
        let l:cmd .= " && ".l:screen_cmd." resize ".l:split_size
        let l:cmd .= " && ".l:screen_cmd." screen"
        let l:cmd .= " && ".l:screen_cmd." \"cd ".a:loc.";"
        let l:cmd .= a:cmd." | tee ".b:splitter_command_log."\""
    elseif a:cfg ==? 'window'
        let l:title = fnamemodify(split(a:cmd)[0], ":t")

        let l:cmd = l:screen_cmd." screen -fn -t 'Running ".l:title." ...' \"cd ".a:loc.";"
        let l:cmd .= a:cmd." | tee ".b:splitter_command_log."\""
        let l:cmd .= " && ".l:screen_cmd." other"
    endif

    if exists("l:cmd")
        call splitter#ExecCmd(l:cmd)
    endif
endfunction

function! splitter#LaunchCommandInNewTerminal(loc, cmd)
    " Determine the terminal to use
    if executable("urxvtc")
        let l:terminal = "urxvtc -e"
    elseif executable("gnome-terminal")
        let l:terminal = "gnome-terminal -e"
    elseif has("win32unix")
        let l:terminal = "/usr/bin/mintty.exe -e"
    endif

    " Build the file and launch the terminal
    if exists("l:terminal")
        " Build the file
        let l:cmd_file = tempname()
        let l:cmd_file_contents = []
        call add(l:cmd_file_contents, "#!/bin/sh")
        call add(l:cmd_file_contents, "cd ".a:loc)
        let l:pipe = (&shell =~? "csh" ? "|&" : "2>&1 |")
        call add(l:cmd_file_contents, a:cmd." ".l:pipe." tee ".b:splitter_command_log)
        call writefile(l:cmd_file_contents, l:cmd_file)
        call system("chmod +x ".l:cmd_file)

        call system(l:terminal." ".l:cmd_file."&")
    endif
endfunction

function! splitter#LaunchCommandHeadless(loc, cmd)
    call splitter#ExecCmd("cd ".a:loc."; ".a:cmd)
endfunction

function! splitter#LaunchCommand(loc, cmd, cfg)
    let b:splitter_command_log = tempname()

    if strlen(a:cmd) > 0
        let l:cmd = a:cmd
    else
        let l:cmd = expand("%:p")
    endif

    if a:cfg ==? 'new_terminal'
        call splitter#LaunchCommandInNewTerminal(a:loc, l:cmd)
    else
        if exists("$TMUX")
            call splitter#LaunchCommandInTmux(a:loc, l:cmd, a:cfg)
        elseif exists("$TERM") && expand("$TERM") == "screen"
            call splitter#LaunchCommandInScreen(a:loc, l:cmd, a:cfg)
        else
            call splitter#LaunchCommandHeadless(a:loc, l:cmd)
        endif
    endif
endfunction

function! splitter#LaunchCommandHere(cmd, cfg)
    call splitter#LaunchCommand(getcwd(), a:cmd, a:cfg)
endfunction
" }}}

function! splitter#RunCommandHandler(bg, here, ...)
    let l:cmd = ""
    let l:loc = getcwd()

    if a:0 > 0
        if a:here
            let l:cmd = join(a:000, ' ')
        else
            let l:loc = a:1
            if a:0 >= 2
                let l:cmd = join(a:000[1:], ' ')
            endif
        endif
    endif

    call splitter#LaunchCommand(l:loc, l:cmd, (a:bg ? 'window' : 'split_horizontal'))
endfunction
