command! T call Window()

function! Window()
    call Open()
    call FocusMarkdown()
endfunction

function! Open()
    set splitright
    
    50vnew
	setlocal bufhidden=wipe
	setlocal nobuflisted
	setlocal buftype=nofile
	silent file `='Index'`
endfunction

function! FocusIndex()
    execute bufwinnr('Index') . 'wincmd w'
endfunction

function! FocusMarkdown()
    call FocusIndex()
    wincmd h
endfunction
