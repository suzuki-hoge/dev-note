command! MI            call MarkdownIndex()
command! MarkdownIndex call MarkdownIndex()

let g:indices = []

function! MarkdownIndex()
    let lines = GetAllLines()
    let g:indices = Filter(lines)

    call Open()

    call PutIndices(ToLines(g:indices))
endfunction

function! PutIndices(lines)
    call FocusIndex()
    call setline('1', a:lines)
endfunction

function! Jump()
    let lineNum = line('.') - 1
    bwipeout
    call setpos('.', [0, g:indices[lineNum]['lineNum'], 0, 0])
endfunction
