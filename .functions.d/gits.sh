gits() {
    git status -sb | head -n 1
    mc=1 dc=1 uc=1 ac=1 sc=1
    local line status path name
    while read -r line; do
        test "$line" || break
        status=${line:0:2}
        path=${line:3}
        case "$status" in
            " M") name=m$((mc++)) ;;
            " D") name=d$((dc++)) ;;
            "??") name=u$((uc++)) ;;
            "A ") name=a$((ac++)) ;;
            "M ") name=s$((sc++)) ;;
            *) echo unsupported status on line: $line
        esac
        printf -v $name "$path"
        echo "$status ($name) $path"
    done <<< "$(git status -s)"
}

# for debugging:
#gits
#set | grep -E '^[mduas](c|[0-9]+)='
