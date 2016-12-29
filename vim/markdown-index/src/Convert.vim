function! Convert()
    let lines = GetAllLines()
    return Filter(lines)
endfunction

function! GetAllLines()
    return getline(1, '$')
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

function! ToLines(indices)
    let result = []

    for i in range(len(a:indices))
        let result = result + [a:indices[i]['line']]
    endfor

    return result
endfunction
