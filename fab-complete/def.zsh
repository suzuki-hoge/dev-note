compdef _fab_complete fab
function _fab_tasks {
    in_header=1
    tasks=()
    IFS_BK=$IFS
    IFS=$'\n'

    fab --list | while read line
    do
        if [[ $in_header -ne 1 ]] ;then
            tasks+=(`echo $line | awk '{printf("%s", $1); $1=""; printf("[%s]", $0)}' | sed -e 's/\[ /\[/g'`)
        fi
        if [[ $line =~ 'Available commands:' ]]; then
            in_header=0
        fi
    done

    _values 'tasks' $tasks
    IFS=$IFS_BK
}

function _fab_complete {
    _arguments \
        '(- *)'{-l,--list}'[print list of possible commands and exit]' \
        '(-f --file)'{-f,--file}"[python module file to import, e.g. '../other.py']:fabric file:_files" \
        '*:tasks:_fab_tasks'
}
