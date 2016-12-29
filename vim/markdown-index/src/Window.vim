function! Open()
    set splitright
    
    50vnew
	setlocal bufhidden=wipe
	setlocal nobuflisted
	setlocal buftype=nofile
	silent file `='Index'`

    nnoremap <buffer> <CR> :call Jump()<CR>
endfunction

function! FocusIndex()
    execute bufwinnr('Index') . 'wincmd w'
endfunction
