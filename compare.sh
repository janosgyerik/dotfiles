#!/bin/sh

cd $(dirname "$0")

cmd=$1

for i in .??*; do
    if test -f ~/$i; then
        if ! cmp $i ~/$i >/dev/null; then
            echo diff $i ~/$i
            echo gvim -d $i ~/$i
            case "$cmd" in
                mvim) mvim -d $i ~/$i ;;
                gvim) gvim -d $i ~/$i ;;
                vim) vim -d $i ~/$i ;;
                diff) diff $i ~/$i | less ;;
            esac
        fi
    fi
done
