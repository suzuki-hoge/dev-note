compdef _fab_complete fab

function _fab_tasks {
    _values 'tasks' 'a[do a]' 'b[delete b]' 'c[search c]'
}

function _fab_complete {
    _arguments \
        '(- *)'{-l,--list}'[list]' \
        '(-f --file)'{-f,--file}'[fabfile]:fabric files:_files' \
        '*:tasks:_fab_tasks'
}
