compdef _fab_complete fab
function _fab_complete {
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
