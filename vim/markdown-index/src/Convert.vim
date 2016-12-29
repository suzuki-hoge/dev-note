command! C call Convert()

function! Convert()
    let lines = GetAllLines()
    let indices = Filter(lines)

    echo indices
endfunction

function! GetAllLines()
    " return getline(1, '$')
    return ['# Header', '## Foo', 'foo', 'foo', '## Bar', 'bar', '### Baz', '```sh', '# comment', '```', '']
endfunction

function! Filter(lines)
    let result = []
    let inCode = 0

    for i in range(len(a:lines))
        if a:lines[i] =~? '^```'
            if inCode == 0
                let inCode = 1
            else
                let inCode = 0
            endif
        endif

        if a:lines[i] =~? '^#' && inCode == 0
            let result = result + [{'lineNum': i + 1, 'line': a:lines[i]}]
        endif
    endfor

    return result
endfunction
